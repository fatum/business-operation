require "business/operation/dsl"
require "business/operation/executor"
require "business/operation/state"

module Business
  module Operation
    class Base
      extend Dsl

      # @return Result
      def self.call(params = {})
        state = State.new(params: params)
        Executor.new(self, state, instructions.to_a).()
      end

      def initialize(state = State.new)
        @state = state
      end

      def run_pileline(context)
        Executor.new(self.class, context.state, self.class.instructions.to_a, context.level).()
      end

      private

      attr_reader :state
    end
  end
end
