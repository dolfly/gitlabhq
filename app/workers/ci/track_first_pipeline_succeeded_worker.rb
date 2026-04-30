# frozen_string_literal: true

module Ci
  class TrackFirstPipelineSucceededWorker
    include ApplicationWorker
    include Gitlab::InternalEventsTracking

    data_consistency :sticky
    feature_category :pipeline_composition
    urgency :low
    idempotent!
    defer_on_database_health_signal :gitlab_ci, [:ci_project_metrics], 1.minute

    def perform(pipeline_id)
      pipeline = Ci::Pipeline.find_by_id(pipeline_id)
      return unless pipeline&.success?

      Ci::ProjectMetric.record_first_pipeline_success!(pipeline.project_id)

      track_internal_event(
        'first_pipeline_succeeded',
        project: pipeline.project,
        user: pipeline.user,
        additional_properties: {
          value: (Time.current - pipeline.project.created_at).to_i
        }
      )
    end
  end
end
