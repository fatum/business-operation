require "business/operation/instructions"

module Business
  module Operation
    module Dsl
      attr_accessor :instructions

      def inherited(base)
        base.instructions = Instructions.new(base)
      end

      def container(value)
        instructions.container = value
      end

      def debug(value)
        instructions.debug = value
      end

      def depends_on(data_category, values = [])
        values = Array(values)
        raise ArgumentError, "#{values} cannot be empty" if values.size.zero?

        instructions.add :depend, nil, Hash[data_category => values]
      end

      def failure(operation = nil, options = {}, &block)
        operation = block if operation.nil? && block_given?
        instructions.add :failure, operation, options.freeze
      end

      def step(operation = nil, options = {}, &block)
        operation = block if operation.nil? && block_given?
        instructions.add :step, operation, options.freeze
      end

      def wrap(operation, options = {})
        instructions.add :wrap, operation, options.freeze
        yield
        instructions.reset!
      end
    end
  end
end
