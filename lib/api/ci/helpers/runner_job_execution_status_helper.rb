# frozen_string_literal: true

module API
  module Ci
    module Helpers
      module RunnerJobExecutionStatusHelper
        # Efficiently determines job execution status for multiple runners using BatchLoader
        # to avoid N+1 queries. Returns :active if runner has running builds, :idle otherwise.
        def lazy_job_execution_status(object:, key:)
          BatchLoader.for(object.id).batch(key: key) do |object_ids, loader|
            if Feature.enabled?(:ci_read_job_execution_status_from_running_builds, Feature.current_request)
              # We ignore `canceling` builds because they're short-lived
              active_ids = object.class.ids_with_running_builds(object_ids).to_set

              object_ids.each do |id|
                loader.call(id, active_ids.include?(id) ? :active : :idle)
              end
            else
              statuses = object.class.id_in(object_ids).with_executing_builds.index_by(&:id)

              object_ids.each do |id|
                loader.call(id, statuses[id] ? :active : :idle)
              end
            end
          end
        end
      end
    end
  end
end
