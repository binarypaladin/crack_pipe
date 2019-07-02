require_relative '../spec_helper'

module CrackPipe
  class Action
    class StepSpec < Minitest::Spec
      it 'stores track, exec, output_override, and context_override' do
        s = Step.new(:default, proc { 'x' }, key: 'value')
        s.exec.call.must_equal('x')
        s.context_override.must_equal(key: 'value')
        s.output_override.must_be_nil
        s.track.must_equal(:default)
      end
    end
  end
end
