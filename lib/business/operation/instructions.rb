module Business
  module Operation
    class Instructions
      attr_accessor :debug, :container

      def initialize(operation)
        @operation = operation
        @operations = []
        @current = []
        @debug = false
      end

      def add(type, handler, options)
        operation = factory(type, handler, options)

        if !@current.empty? && (active = @current.last)
          active.add_child(operation)
        else
          @operations << operation
        end

        @current << operation if type == :wrap
      end

      def empty?
        !any?
      end

      def any?
        @operations.size.positive?
      end

      def reset!
        @current.shift
      end

      def to_a
        @operations
      end

      private

      def factory(type, handler, options)
        instruction_class = case type
                            when :step, :depend, :failure
                              Instruction
                            when :wrap
                              Instruction::Wrap
                            end

        instruction_class.new(
          type,
          handler,
          options,
          _children = [],
          container: container,
          logger: TreeLogger,
          debug: debug
        )
      end
    end
  end
end
