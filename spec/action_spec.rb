require_relative 'spec_helper'

module CrackPipe
  class ActionSpec < Minitest::Spec
    let(:action) do
      Class.new(Action) do
        pass { |_, **| false }
        step :truthy_value?
        step :record_truthy_value_class
        fail :record_failure
        fail :return_error_code

        def truthy_value?(_, value: nil, **)
          pass!(value) if value == :short_circuit
          fail!(value) if value == :short_circuit!
          value
        end

        def record_truthy_value_class(ctx, value:, **)
          ctx[:value_class] = value.class.name
          value
        end

        def record_failure(ctx, value: nil, **)
          ctx[:failure_msg] =
            "`value` should be a truthy value. Instead it was `#{value}`."
        end

        def return_error_code(_, **)
          :custom_error_code_01
        end
      end
    end

    let(:nesting_action) do
      klass = action

      Class.new(Action) do
        step :before
        step klass
        step :after
        fail :after_fail

        def before(ctx, **)
          ctx[:before] = true
        end

        def after(ctx, value:, **)
          ctx[:after] = true
          value.to_s.upcase
        end

        def after_fail(ctx, **)
          :custom_error_code_02
        end
      end
    end

    it 'results in a success with a truthy value' do
      r = action.(value: 'x')
      r.history.size.must_equal(3)
      r.history.select { |h| h[:next] == :default }.size.must_equal(3)

      assert r.success?
      r.output.must_equal('x')
      r[:value].must_equal('x')
      r[:value_class].must_equal('String')
      refute r.context.key?(:failure_msg)
    end

    it 'results in a failure and uses the fail track with a falsy value' do
      r = action.(value: false)
      r.history.size.must_equal(4)
      r.history.select { |h| h[:next] == :fail }.size.must_equal(3)

      assert r.failure?
      r.output.must_equal(:custom_error_code_01)
      r[:failure_msg].must_match(/false/)
      r[:value].must_equal(false)
    end

    it 'short circuits execution with `pass!`' do
      r = action.new.(value: :short_circuit)
      r.history.size.must_equal(2)

      assert r.success?
      r.output.must_equal(:short_circuit)
    end

    it 'short circuits execution with `fail!`' do
      r = action.(value: :short_circuit!)
      assert r.failure?
      r.output.must_equal(:short_circuit!)
    end

    it 'nests one action in another' do
      r = nesting_action.(value: 'x')
      r.history.size.must_equal(5)

      r.output.must_equal('X')
      r[:after].must_equal(true)
      r[:before].must_equal(true)
      r[:value_class].must_equal('String')

      r = nesting_action.(value: false)
      r.history.size.must_equal(6)

      r.output.must_equal(:custom_error_code_02)
      r[:before].must_equal(true)

      r = nesting_action.(value: :short_circuit!)
      assert r.failure?
      r.output.must_equal(:short_circuit!)
    end
  end
end
