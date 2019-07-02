# frozen-string-literal: true

module CrackPipe
  class Action
    class Result
      attr_reader :context, :history, :output

      def initialize(history)
        last_result = history.last
        @context = last_result[:context]
        @history = history
        @output = last_result[:output]
        @success = last_result[:success]
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
