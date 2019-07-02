# frozen-string-literal: true

module CrackPipe
  class Action
    class Signal
      attr_reader :success, :type, :value

      def initialize(type, value, success = nil)
        @type = type
        @value = value
        @success = success
      end
    end
  end
end
