# frozen_string_literal: true

module Business
  module Operation
    class Instruction
      class Wrap < self
        def call(context, &block)
          strings = [
            "Execute instruction ",
            "type=#{type} handler=#{handler || :none} state=#{context.state}"
          ]

          log(strings.join, context.level)

          case @handler
          when Symbol
            if context.operation.method(@handler).arity.zero?
              context.operation.send(@handler, &block)
            else
              context.operation.send(@handler, @options, &block)
            end
          else
            instance = @handler.new(context.state)

            if instance.method(:call).arity.zero?
              instance.(&block)
            else
              instance.(@options, &block)
            end
          end
        end
      end

      attr_reader :type, :handler, :options, :children

      def initialize(type, handler, options = {}, children = [], settings = {})
        @type = type
        @handler = handler
        @options = options
        @children = children
        @settings = settings
      end

      def call(context)
        log("Execute instruction", context.level)

        case @handler
        when Proc
          @handler.(context.state)
        when Symbol
          if context.operation.method(@handler).arity.zero?
            context.operation.send(@handler)
          else
            context.operation.send(@handler, @options)
          end
        when String
          unless container
            raise Error, "Can't execute container's entry '#{@handler}'. " \
                         "You have to attach container to operation"
          end

          instance = container.resolve(@handler)

          unless instance
            raise Error, "Can't execute container's entry '#{@handler}'. " \
                         "Not found"
          end

          instance = instance.is_a?(Proc) ? instance.(context.state) : instance

          execute_operation(instance.new(context.state), context)
        else
          execute_operation(@handler.new(context.state), context)
        end
      end

      def add_child(instruction)
        @children << instruction
      end

      def can_fail?(result)
        return false if type == :failure || result

        options.fetch(:fail, true)
      end

      private

      def log(msg, level)
        logger&.log_tree(msg, level) if @settings[:debug]
      end

      def execute_operation(instance, context)
        if instance.respond_to?(:call)
          if instance.method(:call).arity.zero?
            instance.()
          else
            instance.(@options)
          end
        else
          # Operation should define :call method or use pipeline (steps) to organize business logic
          instance.run_pileline(context)
        end
      end

      def logger
        return @logger if defined?(@logger)

        @logger = @settings[:logger].new(self) if @settings[:logger]
      end

      def container
        @settings[:container]
      end
    end
  end
end
