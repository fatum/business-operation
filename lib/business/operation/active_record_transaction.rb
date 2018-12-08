module Business
  module Operation
    class ActiveRecordTransaction < Business::Operation::Base
      def call(options = nil, &block)
        ActiveRecord::Base.transaction(options, &block)
      end
    end
  end
end
