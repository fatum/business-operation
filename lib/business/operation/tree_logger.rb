require "logger"

module Business
  module Operation
    class TreeLogger < Struct.new(:instruction)
      def log_tree(message, level)
        delimiters = "  " * level

        strings = [
          delimiters,
          "-> ",
          message,
          " type=#{instruction.type} handler=#{instruction.handler || :none}"
        ]

        strings << " options=#{instruction.options}"

        log(strings.join)
      end

      def log(message)
        logger.info(message)
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end
    end
  end
end
