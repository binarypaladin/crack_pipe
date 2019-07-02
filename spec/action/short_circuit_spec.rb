require_relative '../spec_helper'

module CrackPipe
  class Action
    class ShortCircuitSpec < Minitest::Spec
      it 'stores a value and success' do
        sc = ShortCircuit.new('x', true)
        sc.value.must_equal('x')
        sc.success.must_equal(true)
      end

      # NOTE: A `nil` value in `success` is intended for actions to determine
      # `success` based upon `value`.
      it 'specifically allows a nil success' do
        sc = ShortCircuit.new('a')
        sc.success.must_be_nil
      end
    end
  end
end
