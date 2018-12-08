require "business/operation/execution_context"

module Business
  module Operation
    class Executor
      def initialize(operation, state, instructions, level = 0)
        @operation = operation.new(state)
        @executed = false
        @state = state
        @instructions = instructions
        @required_keys = []
        @level = level
      end

      def call
        iterate(@instructions)
      end

      private

      def wrap(instruction)
        instruction.(build_context) do
          iterate(instruction.children)
        end
      end

      def run(instruction)
        @required_keys.each do |key|
          options[key] || \
            raise(Business::Operation::Error, "Cannot find required key on #{instruction.options}")
        end

        instruction.(build_context).tap do |result|
          @state.fail! if instruction.can_fail?(result)
        end
      end

      def iterate(instructions)
        @level += 1

        instructions.each_with_index do |instruction, i|
          if @state.failed?
            run_failures(instructions, i)
            break
          end

          case instruction.type
          when :step
            run(instruction)
          when :wrap
            wrap(instruction)
          when :depend
            if instruction.options[:state]
              check_required(instruction, :state)
            elsif instruction.options[:params]
              check_required(instruction, :params)
            elsif (keys = instruction.options[:options])
              @required_keys = keys
            end
          end
        end

        # Execute current operation after whole pipeline
        @operation.(@state[:params]) if @operation.respond_to?(:call) && !@executed

        @state
      end

      def run_failures(instructions, i)
        handlers = instructions.drop(i).select do |instruction|
          instruction.type == :failure
        end

        handlers.each do |instruction|
          run(instruction)
          break if instruction.options[:fail_fast]
        end
      end

      def build_context
        ExecutionContext.new.tap do |context|
          context.operation = @operation
          context.state = @state
          context.level = @level
        end
      end

      def check_required(instruction, entry)
        instruction.options[entry].each do |key|
          @state[key] || \
            raise(Business::Operation::Error, "Cannot find required key :#{key} on #{@state}")
        end
      end
    end
  end
end
