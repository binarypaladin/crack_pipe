# frozen-string-literal: true

module CrackPipe
  class Action
    class ShortCircuit
      attr_reader :success, :value

      def initialize(value, success = nil)
        @value = value
        @success = success
      end
    end
  end
end
