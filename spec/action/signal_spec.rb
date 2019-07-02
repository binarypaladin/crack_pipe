require_relative '../spec_helper'

module CrackPipe
  class Action
    class SignalSpec < Minitest::Spec
      it 'stores a value and success' do
        sc = Signal.new(:halt, 'x', true)
        sc.success.must_equal(true)
        sc.type.must_equal(:halt)
        sc.value.must_equal('x')
      end

      # NOTE: A `nil` value in `success` is intended for actions to determine
      # `success` based upon `value`.
      it 'specifically allows a nil success' do
        sc = Signal.new(:halt, 'a')
        sc.success.must_be_nil
      end
    end
  end
end
