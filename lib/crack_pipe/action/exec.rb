# frozen-string-literal: true

require 'crack_pipe/action/signal'

module CrackPipe
  class Action
    module Exec
      class << self
        def call(action, context, track = :default)
          Result.new(action(action, context, track))
        end

        def action(action, context, track = :default)
          action.class.steps.each_with_object([]) do |s, results|
            next unless track == s.track
            results!(results, action, s, context).last.tap do |r|
              action.after_flow_control(r)
              context = r[:context]
              track = r[:next]
              return results if r[:signal] == :halt
            end
          end
        end

        def flow_control_hash(action, step, context, output)
          success = success_with_step?(action, step, output)

          {
            exec: step.exec,
            track: step.track,
            next: success ? step.track : :fail,
            context: context.dup
          }.merge(flow_control_with_output(output, success))
        end

        def flow_control_with_output(output, success)
          case output
          when Signal
            {
              signal: output.type,
              output: output.value,
              success: output.success.nil? ? success : output.success
            }
          else
            { output: output, success: success }
          end
        end

        def halt(output, success = nil)
          throw(:signal, Signal.new(:halt, output, success))
        end

        def step(action, step, context)
          kwargs = kwargs_with_context(action, context)

          output = catch(:signal) do
            if (e = step.exec).is_a?(Symbol)
              action.public_send(e, context, **kwargs)
            else
              e.call(context, **kwargs)
            end
          end

          action.after_step(output)
        end

        def success_with_step?(action, step, output)
          step.always_pass? || step.track != :fail && !action.failure?(output)
        end

        private

        def kwargs_with_context(action, context)
          return context if action.kwargs_overrides.empty?
          context.merge(action.kwargs_overrides)
        end

        def results!(results, action, step, context)
          o = step(action, step, context)
          return results.concat(o.history) if o.is_a?(Result)
          results << flow_control_hash(action, step, context, o)
        end
      end
    end
  end
end
