module Business
  module Operation
    class State
      def initialize(data = {})
        @data = data
        @failed = false
      end

      def success?
        !@failed
      end

      def successful?
        !@failed
      end

      def failed?
        @failed
      end

      def fail!
        @failed = true
      end

      def [](key)
        @data[key]
      end

      def []=(key, value)
        unless key.is_a?(Symbol)
          raise ArgumentError, "Please, be consistent in using state keys. Symbols only allowed"
        end

        @data[key] = value
      end

      def to_s
        @data.to_s
      end
    end
  end
end
