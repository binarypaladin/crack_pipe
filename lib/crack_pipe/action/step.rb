# frozen-string-literal: true

module CrackPipe
  class Action
    class Step
      attr_reader :exec, :track

      def initialize(exec = nil, always_pass: false, track: :default, **, &blk)
        if block_given?
          raise ArgumentError, '`exec` must be `nil` with a block' unless
            exec.nil?
          exec = blk
        end

        @always_pass = always_pass
        @exec = instantiate_action(exec)
        @track = track
      end

      def always_pass?
        @always_pass
      end

      private

      # NOTE: This allows actions to be passed in as a class rather than as an
      # instance. It's the difference betweem `step SomeAction` vs
      # `step SomeAction.new` when nesting actions.
      def instantiate_action(obj)
        return obj.new if obj.is_a?(Class) && obj < Action
        obj
      end
    end
  end
end
