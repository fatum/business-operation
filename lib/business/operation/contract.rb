module Business
  module Operation
    class Contract < Base
      depends_on :state, :model
      depends_on :options, :class

      def call(options)
        state[:contract] = options[:class].new(state[:model])

        validated = state[:contract].validate(params(options)) if options.fetch(:validate, true)

        if validated && options.fetch(:persist, true)
          state[:contract].save
        else
          validated.nil? ? true : validated
        end
      end

      private

      def params(options)
        @params ||= options[:key] ? state[:params][options[:key]] : state[:params]
      end
    end
  end
end
