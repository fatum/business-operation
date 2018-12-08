module Business
  module Operation
    class Model < Business::Operation::Base
      DEFAULT_METHOD = :new
      DEFAULT_KEY = :resource

      depends_on :state, :params
      depends_on :options, :class

      def call(options)
        method = options.fetch(:method, DEFAULT_METHOD)
        model = options[:class]

        unless method == DEFAULT_METHOD
          key = options.fetch(:key, DEFAULT_KEY)
          params = state[:params][key]
          id = params[:id] || params["id"]
        end

        case method
        when :new
          state[:model] = model.new
        when :find
          state[:model] = model.find(id)
        when :find_by
          state[:model] = model.find_by(id: id)
        end
      end
    end
  end
end
