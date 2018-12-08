module Business
  module Operation
    class Pundit < Base
      depends_on :state, %i[model params]
      depends_on :options, %i[class action]
      depends_on :params, :current_user

      def call(options)
        current_user = state[:params][:current_user]
        action = options[:action]
        policy = options[:class]

        policy.new(current_user, state[:model]).public_send(action)
      end
    end
  end
end
