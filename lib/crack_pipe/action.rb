# frozen-string-literal: true

require 'crack_pipe/action/result'
require 'crack_pipe/action/short_circuit'
require 'crack_pipe/action/step'

module CrackPipe
  class Action
    @steps = []

    class << self
      attr_reader :steps

      def call(context, &blk)
        new(context, steps, &blk).result
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@steps, @steps.dup)
        super
      end

      private

      def fail(exec = nil, **kwargs, &blk)
        step(exec, kwargs.merge(track: :fail), &blk)
      end

      def pass(exec = nil, **kwargs, &blk)
        step(exec, kwargs.merge(output_override: true), &blk)
      end

      def step(
        exec = nil,
        output_override: nil,
        track: :default,
        **opts,
        &blk
      )
        if block_given?
          raise ArgumentError, '`exec` must be `nil` with a block' unless
            exec.nil?
          exec = blk
        end
        @steps += [Step.new(track, exec, output_override, opts)]
      end
    end

    attr_reader :history, :result

    def initialize(context, steps = self.class.steps, &blk)
      @history = []
      _result!(context.dup, steps.dup, &blk)
    end

    # NOTE: While this hook does nothing by default, it is here with the
    # intention of dealing with potential default values being generated either
    # for output or adding values to the context. A common example would be
    # returning some kind of default failure object in place of a literal `nil`
    # or `false`.
    def after_step(output, _context, _step)
      output
    end

    def fail!(value)
      ShortCircuit.new(value, false)
    end

    def pass!(value)
      ShortCircuit.new(value, true)
    end

    def step_failure?(output)
      case output
      when Result
        output.failure?
      else
        !output
      end
    end

    def to_a
      history.dup
    end

    private

    def _action?(obj)
      obj.is_a?(Class) && obj < Action
    end

    def _exec_nested!(context, action)
      @history += action.new(context).history
      @history.last.tap { |h| context.merge!(h[:context]) }
    end

    def _exec_step!(context, step)
      e = step.exec
      return _exec_nested!(context, e) if _action?(e)

      output =
        case e
        when Symbol
          public_send(e, context, **context)
        when Proc
          instance_exec(context, **context, &e)
        else
          e.call(context, **context)
        end

      _wrap_output(after_step(output, context, step), context.dup, step)
        .tap { |wo| @history << wo }
    end

    def _exec_steps!(context, steps)
      next_track = :default
      steps.map do |s|
        next unless next_track == s.track
        _exec_step!(context, s).tap do |wrapped_output|
          next_track =
            wrapped_output[:short_circuit] ? nil : wrapped_output[:next_track]
        end
      end.compact.last
    end

    def _output_hash(output, step)
      output = step.output_override unless step.output_override.nil?
      success = step.track != :fail && !step_failure?(output)
      case output
      when ShortCircuit
        {
          output: output.value,
          short_circuit: true,
          success: output.success.nil? ? success : output.success
        }
      else
        {
          output: output,
          short_circuit: false,
          success: success
        }
      end
    end

    # NOTE: The optional block here allows you to wrap the the execution in
    # external functionality, such as a default `rescue` or something like a
    # database transaction if it's necessary to span multiple steps.
    def _result!(context, steps)
      if block_given?
        yield(@result = Result.new(_exec_steps!(context, steps)))
      else
        @result = Result.new(_exec_steps!(context, steps))
      end
      @result
    end

    def _wrap_output(output, context, step)
      wrapped_output = _output_hash(after_step(output, context, step), step)
      {
        exec: step.exec,
        next_track: wrapped_output[:success] ? :default : :fail,
        context: context
      }.merge(wrapped_output)
    end
  end
end
