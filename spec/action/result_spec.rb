require_relative '../spec_helper'

module CrackPipe
  class Action
    class ResultSpec < Minitest::Spec
      it 'stores success, output, and context' do
        r = Result.new(context: { a: 1 }, output: 42, success: true)
        r.output.must_equal(42)
        r[:a].must_equal(1)
        r[:b].must_be_nil
        assert r.success?
        refute r.failure?

        r = Result.new(success: false)
        assert r.failure?
        refute r.success?
      end
    end
  end
end
