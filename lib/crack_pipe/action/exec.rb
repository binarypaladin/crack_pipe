# frozen-string-literal: true

require 'crack_pipe/action/signal'

module CrackPipe
  class Action
    module Exec
      class << self
        def call(action, context, track = :default)
          Result.new(action(action, context, [], track))
        end

        def action(action, context, results = [], track = :default)
          action.steps.each_with_object(results) do |s, rslts|
            next unless track == s.track

            if s.exec.is_a?(Action)
              self.action(s.exec, context, rslts)
            else
              rslts << step(action, s, context)
            end

            rslts.last.tap do |r|
              context = r[:context]
              track = r[:next]
              return rslts if r[:signal] == :halt
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
          output = catch(:signal) do
            case (e = step.exec)
            when Symbol
              action.public_send(e, context, **context)
            when Proc
              action.instance_exec(context, **context, &e)
            else
              e.call(context, **context)
            end
          end

          action.after_step(flow_control_hash(action, step, context, output))
        end

        def success_with_step?(action, step, output)
          step.always_pass? || step.track != :fail && !action.failure?(output)
        end
      end
    end
  end
end
