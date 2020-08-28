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

        def after_fail(_ctx, **)
          :custom_error_code_02
        end
      end
    end

    let(:action_with_skips) do
      klass = skipped_action

      Class.new(Action) do
        step :before
        step klass, if: ->(ctx, **) { ctx[:run_all_steps] }
        step :always_run, if: true
        step :never_run, if: false
        step :conditional_method, if: :run_all_steps?

        def before(ctx, **)
          ctx[:before] = true
        end

        def conditional_method(ctx, **)
          ctx[:conditional_method] = "exec'd"
        end

        def always_run(ctx, **)
          ctx[:always_run] = true
        end

        def never_run(ctx, **)
          ctx[:never_run] = true
        end

        def run_all_steps?(_, run_all_steps:, **)
          run_all_steps
        end
      end
    end

    let(:skipped_action) do
      Class.new(Action) do
        step :maybe_hit_1
        step :maybe_hit_2

        def maybe_hit_1(ctx, **)
          ctx[:maybe_hit_1] = true
        end

        def maybe_hit_2(ctx, **)
          ctx[:maybe_hit_2] = true
        end
      end
    end

    it 'conditionally skips steps' do
      r = action_with_skips.call(run_all_steps: false)
      r.history.size.must_equal(5)
      assert r.success?
      assert r[:before]
      assert r[:always_run]
      refute r.context.key?(:never_run)
      refute r.context.key?(:maybe_hit_1)
      refute r.context.key?(:maybe_hit_2)
      refute r.context.key?(:conditional_method)
      r.output.must_equal(:skipped)
      r.history.select { |h| h[:output] == :skipped }.size.must_equal(3)

      r = action_with_skips.call(run_all_steps: true)
      r.history.size.must_equal(6)
      assert r.success?
      assert r[:always_run]
      assert r[:maybe_hit_1]
      assert r[:maybe_hit_2]
      refute r.context.key?(:never_run)
      r[:conditional_method].must_equal("exec'd")
      r.output.must_equal("exec'd")
    end

    it 'results in a success with a truthy value' do
      r = action.call(value: 'x')
      r.history.size.must_equal(3)
      r.history.select { |h| h[:next] == :default }.size.must_equal(3)

      assert r.success?
      r.output.must_equal('x')
      r[:value].must_equal('x')
      r[:value_class].must_equal('String')
      refute r.context.key?(:failure_msg)
    end

    it 'results in a failure and uses the fail track with a falsy value' do
      r = action.call(value: false)
      r.history.size.must_equal(4)
      r.history.select { |h| h[:next] == :fail }.size.must_equal(3)

      assert r.failure?
      r.output.must_equal(:custom_error_code_01)
      r[:failure_msg].must_match(/false/)
      r[:value].must_equal(false)
    end

    it 'short circuits execution with `pass!`' do
      r = action.new.call(value: :short_circuit)
      r.history.size.must_equal(2)

      assert r.success?
      r.output.must_equal(:short_circuit)
    end

    it 'short circuits execution with `fail!`' do
      r = action.call(value: :short_circuit!)
      assert r.failure?
      r.output.must_equal(:short_circuit!)
    end

    it 'nests one action in another' do
      r = nesting_action.call(value: 'x')
      r.history.size.must_equal(5)

      r.output.must_equal('X')
      r[:after].must_equal(true)
      r[:before].must_equal(true)
      r[:value_class].must_equal('String')

      r = nesting_action.call(value: false)
      r.history.size.must_equal(6)

      r.output.must_equal(:custom_error_code_02)
      r[:before].must_equal(true)

      r = nesting_action.call(value: :short_circuit!)
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

      r = a.call({})
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

      r = a.call({})
      r.history[0][:context][:one].must_equal('one')
      r.output.must_equal('one!')
    end
  end
end
