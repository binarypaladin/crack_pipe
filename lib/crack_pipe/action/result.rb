# frozen-string-literal: true

module CrackPipe
  class Action
    class Result
      attr_reader :context, :output

      def initialize(context: {}, output: nil, success:, **)
        @context = context
        @output = output
        @success = success
      end

      def [](key)
        @context[key]
      end

      def failure?
        !@success
      end

      def success?
        @success
      end
    end
  end
end
