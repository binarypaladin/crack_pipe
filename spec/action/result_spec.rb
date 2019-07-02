require_relative '../spec_helper'

module CrackPipe
  class Action
    class ResultSpec < Minitest::Spec
      it 'stores infers context, output, and success from history' do
        h = [
          { context: { a: 1 }, output: 21, success: true },
          { context: { a: 1, b: 2 }, output: 42, success: true }
        ]

        r = Result.new(h)
        r.output.must_equal(42)
        r[:a].must_equal(1)
        r[:b].must_equal(2)
        assert r.success?
        refute r.failure?

        r = Result.new([{ success: false }])
        assert r.failure?
        refute r.success?
      end
    end
  end
end
