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

    it 'works with a simple action with no context' do
      action = Class.new(Action) do
        step :truthy

        def truthy(ctx, **)
          ctx[:key] = true
        end
      end

      r = action.call
      assert r.success?
      r[:key].must_equal(true)
    end

    it 'executes `after_step` hook' do
      a = Class.new(Action) do
        step :one
        step :two

        def one(*)
          1
        end

        def two(*)
          :two
        end

        def after_step(output)
          output.is_a?(Symbol) ? output.to_s : super
        end
      end

      r = a.({})
      r.history[0][:output].must_equal(1)
      r.history[1][:output].must_equal('two')
    end

    it 'executes `after_flow_control` hook' do
      a = Class.new(Action) do
        step :one
        step :two

        def one(*)
          :one
        end

        def two(_, one:, **)
          "#{one}!"
        end

        def after_flow_control(flow_control_hash)
          o = flow_control_hash[:output]
          flow_control_hash[:context][o] = o.to_s if o.is_a?(Symbol)
          super
        end
      end

      r = a.({})
      r.history[0][:context][:one].must_equal('one')
      r.output.must_equal('one!')
    end
  end
end
