# frozen_string_literal: true

require 'test_helper'

# TODO: to_s / to_str
# TODO: ==
# TODO:
# a test that we use Procs and that we return from where the closure is defined,
# not just from the block

class OptionRbTest < Minitest::Test
  include OptionRb

  context 'class methods ->' do
    context 'some() ->' do
      should 'return a Some wrapping some value' do
        some = Option.some(2)

        assert some.some?
        assert_equal 2, some.unwrap
      end
    end

    context 'none() ->' do
      should 'return a None' do
        assert Option.none.none?
      end
    end

    context 'from() ->' do
      should "return a Some wrapping the argument if it's not nil" do
        from = Option.from(2)

        assert from.some?
        assert_equal 2, from.unwrap
      end

      should 'return a None if the argument is nil' do
        assert Option.from(nil).none?
      end
    end
  end

  context 'match() ->' do
    should 'raise an error if no block is given' do
      assert_raises(ArgumentError) do
        Option.some(1).match
      end
    end

    should "raise an error if the match isn't exhaustive" do
      assert_raises(RuntimeError) do
        Option.some(1).match do
          Some { |value| value + 1 }
        end
      end

      assert_raises(RuntimeError) do
        Option.some(1).match do
          None { 0 }
        end
      end
    end

    should 'raise an error if Some or None is specified more than once' do
      assert_raises(RuntimeError) do
        Option.some(1).match do
          Some { |value| value + 1 }
          Some { |value| value + 1 }
          None { 0 }
        end
      end

      assert_raises(RuntimeError) do
        Option.some(1).match do
          Some { |value| value + 1 }
          None { 0 }
          None { 0 }
        end
      end
    end
  end

  context 'lmatch() ->' do
    should "not raise an error if the match isn't exhaustive" do
      Option.some(1).lmatch do
        Some { |value| value + 1 }
      end

      Option.some(1).lmatch do
        None { 0 }
      end

      Option.some(1).lmatch { nil }
    end
  end

  context 'Some ->' do
    setup do
      @option = Option.some(1)
    end

    context 'match() ->' do
      should 'return the value returned by the Some arm' do
        result = @option.match do
          Some { |value| value + 10 }
          None { 0 }
        end

        assert_equal 11, result
      end
    end

    context 'some? ->' do
      should 'return true' do
        assert @option.some?
      end
    end

    context 'none? ->' do
      should 'return false' do
        refute @option.none?
      end
    end

    context 'unwrap() ->' do
      should 'return the inner value' do
        assert_equal 1, @option.unwrap
      end
    end

    context 'expect() ->' do
      should 'return the inner value' do
        assert_equal 1, @option.expect('custom error message')
      end
    end

    context 'unwrap_or() ->' do
      should 'return the inner value' do
        assert_equal 1, @option.unwrap_or('default')
      end
    end

    context 'unwrap_or_else() ->' do
      should 'return the inner value' do
        assert_equal(1, @option.unwrap_or_else { 'default' })
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.unwrap_or_else
        end
      end
    end

    context 'map() ->' do
      should 'return a new Some containing the value returned by the block' do
        result = @option.map { |value| value + 10 }
        assert_equal Option.some(11), result
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.map
        end
      end
    end

    context 'map_or() ->' do
      should 'return the value returned by the block' do
        result = @option.map_or('default') { |value| value + 10 }
        assert_equal 11, result
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.map_or('default')
        end
      end
    end

    context 'map_or_else() ->' do
      should 'return the value returned by the second argument' do
        result = @option.map_or_else(-> { 'default' }, ->(value) { value + 10 })
        assert_equal 11, result
      end
    end

    context 'and() ->' do
      should 'return the second option if it is Some' do
        assert_equal Option.some(2), @option.and(Option.some(2))
      end

      should 'return None if the second option is None' do
        assert_equal Option.none, @option.and(Option.none)
      end
    end

    context 'and_then() ->' do
      should 'call the function with the wrapped value and return the result' do
        result = @option.and_then { |value| Option.some(value + 10) }
        assert_equal Option.some(11), result

        result = @option.and_then { Option.none }
        assert_equal Option.none, result
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.and_then
        end
      end
    end

    context 'filter() ->' do
      should 'return self if the predicate returns true' do
        assert_equal Option.some(1), @option.filter(&:odd?)
      end

      should 'return None if the predicate returns false' do
        assert_equal Option.none, @option.filter(&:even?)
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.filter
        end
      end
    end

    context 'or() ->' do
      should 'return the other option if it is Some' do
        assert_equal Option.some(1), @option.or(Option.some(2))
      end

      should 'return self if the other option is None' do
        assert_equal Option.some(1), @option.or(Option.none)
      end
    end

    context 'or_else() ->' do
      should 'return self' do
        result = @option.or_else { Option.some(11) }
        assert_equal @option, result
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.or_else
        end
      end
    end

    context 'xor() ->' do
      should 'return self if the other option is None' do
        assert_equal @option, @option.xor(Option.none)
      end

      should 'return None if the other option is Some' do
        assert_equal Option.none, @option.xor(Option.some(2))
      end
    end

    context 'contains?() ->' do
      should 'return if the option contains the given value' do
        assert @option.contains? 1
        refute @option.contains? 0
      end
    end

    context 'flatten() ->' do
      setup { @option = Option.some(Option.some(1)) }

      should 'return the inner Option' do
        assert_equal Option.some(1), @option.flatten
      end
    end

    context 'zip() ->' do
      should 'return None if the other option is None' do
        assert @option.zip(Option.none).none?
      end

      should 'return a Some with both values if the other option is Some' do
        assert Option.some([1, 2]), @option.zip(Option.some(2))
      end
    end

    context 'to_s() ->' do
      should 'return the variant and the inner value' do
        assert_equal 'Some(1)', @option.to_s
      end
    end

    context 'equality operator (==) ->' do
      should 'return false if the other option is None' do
        refute @option == Option.none
      end

      should 'return true if the other option contains the same inner value' do
        result = @option == Option.some(1)
        assert result

        result = @option == Option.some(2)
        refute result
      end
    end
  end

  context 'None:' do
    setup do
      @option = Option.none
    end

    context 'match() ->' do
      should 'return the value returned by the None arm' do
        result = @option.match do
          Some { |value| value + 10 }
          None { 0 }
        end

        assert_equal 0, result
      end
    end

    context 'some? ->' do
      should 'return false' do
        refute @option.some?
      end
    end

    context 'none? ->' do
      should 'return true' do
        assert @option.none?
      end
    end

    context 'unwrap() ->' do
      should 'raise an error' do
        assert_raises(UnwrapError) { @option.unwrap }
      end
    end

    context 'expect() ->' do
      should 'raise an error with the custom error message' do
        assert_raises(UnwrapError) do
          @option.expect('custom error message')
        rescue UnwrapError => e
          assert_equal 'custom error message', e.message
          raise e
        end
      end
    end

    context 'unwrap_or() ->' do
      should 'return the default value' do
        assert_equal 'default', @option.unwrap_or('default')
      end
    end

    context 'unwrap_or_else() ->' do
      should 'return the value returned by the block that was passed' do
        assert_equal('default', @option.unwrap_or_else { 'default' })
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.unwrap_or_else
        end
      end
    end

    context 'map() ->' do
      should 'return None' do
        mapped = @option.map { |value| value + 10 }

        assert mapped.none?
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.map
        end
      end
    end

    context 'map_or() ->' do
      should 'return the default value' do
        result = @option.map_or('default') { |value| value + 10 }
        assert_equal 'default', result
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.map_or('default')
        end
      end
    end

    context 'map_or_else() ->' do
      should 'return the value returned by the first argument' do
        result = @option.map_or_else(
          -> { 'default' },
          ->(value) { value + 10 }
        )

        assert_equal 'default', result
      end
    end

    context 'and() ->' do
      should 'always return None' do
        assert @option.and(Option.some(2)).none?
        assert @option.and(Option.none).none?
      end
    end

    context 'and_then() ->' do
      should 'always return None' do
        assert @option.and_then { |value| Option.some(value + 10) }.none?
        assert @option.and_then { Option.none }.none?
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.and_then
        end
      end
    end

    context 'filter() ->' do
      should 'always return None' do
        assert_equal Option.none, @option.filter(&:odd?)
        assert_equal Option.none, @option.filter(&:even?)
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.filter
        end
      end
    end

    context 'or() ->' do
      should 'always return the other option' do
        assert_equal Option.some(2), @option.or(Option.some(2))
        assert @option.or(Option.none).none?
      end
    end

    context 'or_else() ->' do
      should 'return the value returned by the block argument' do
        result = @option.or_else { Option.some(11) }
        assert_equal Option.some(11), result
      end

      should 'raise an error if no block is given' do
        assert_raises(ArgumentError) do
          @option.or_else
        end
      end
    end

    context 'xor() ->' do
      should 'return None if the other option is None' do
        assert @option.xor(Option.none).none?
      end

      should 'return the other option if it is Some' do
        assert_equal Option.some(2), @option.xor(Option.some(2))
      end
    end

    context 'contains?() ->' do
      should 'always return false' do
        refute @option.contains? 1
        refute @option.contains? 0
      end
    end

    context 'flatten() ->' do
      should 'return None()' do
        assert @option.flatten.none?
      end
    end

    context 'zip() ->' do
      should 'return None' do
        assert @option.zip(Option.none).none?
        assert @option.zip(Option.some(2)).none?
      end
    end

    context 'to_s() ->' do
      should 'return the variant' do
        assert_equal 'None', @option.to_s
      end
    end

    context 'equality operator (==) ->' do
      should 'return true if the other option is None' do
        result = @option == Option.none
        assert result
      end

      should 'return false if the other option is None' do
        result = @option == Option.some(1)
        refute result
      end
    end
  end
end
