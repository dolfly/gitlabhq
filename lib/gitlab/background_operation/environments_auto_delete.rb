# frozen_string_literal: true

module Gitlab
  module BackgroundOperation
    class EnvironmentsAutoDelete < BaseOperationWorker
      operation_name :delete_all
      feature_category :continuous_delivery
      cursor :id

      scope_to ->(relation) { relation.where(state: :stopped).where(auto_delete_at: ...Time.current) } # rubocop:disable CodeReuse/ActiveRecord -- Specific use-case
      reset_cursor!

      def perform
        each_sub_batch do |sub_batch|
          ::Environment.id_in(sub_batch.select(:id)).find_each(&:destroy) # rubocop:disable CodeReuse/ActiveRecord -- Need actual model for fast_destroy callbacks
        end
      end
    end
  end
end
