# frozen-string-literal: true

module CrackPipe
  class Action
    class Step
      attr_reader :exec, :context_override, :desc, :output_override, :track

      def initialize(
        track,
        exec,
        output_override = nil,
        **context_override
      )
        @context_override = context_override.dup
        @exec = exec
        @output_override = output_override
        @track = track
      end
    end
  end
end
