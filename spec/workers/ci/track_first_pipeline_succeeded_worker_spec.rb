# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TrackFirstPipelineSucceededWorker, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:perform) { described_class.new.perform(pipeline.id) }

  describe '#perform' do
    context 'when pipeline succeeded and is the first for the project' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }

      it 'fires internal event with time-to-first-pipeline value' do
        freeze_time do
          expected_ttfp = (Time.current - project.created_at).to_i

          expect { perform }
            .to trigger_internal_events('first_pipeline_succeeded')
            .with(project: project, user: user, additional_properties: { value: expected_ttfp })
            .once
        end
      end

      it 'creates a ci_project_metrics record' do
        expect { perform }.to change { Ci::ProjectMetric.count }.by(1)

        metric = Ci::ProjectMetric.find_by(project_id: project.id)
        expect(metric.first_pipeline_succeeded_at).to be_present
      end
    end

    context 'when project already has a recorded first pipeline success' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }

      before do
        create(:ci_project_metric, :with_first_pipeline_succeeded, project: project)
      end

      it 'still calls record_first_pipeline_success! and fires the event' do
        expect(Ci::ProjectMetric).to receive(:record_first_pipeline_success!).with(project.id).and_call_original

        expect { perform }
          .to trigger_internal_events('first_pipeline_succeeded')
          .with(project: project, user: user)
          .once
      end

      it 'does not create a new ci_project_metrics record' do
        expect { perform }.not_to change { Ci::ProjectMetric.count }
      end
    end

    context 'when a ci_project_metrics row exists with nil first_pipeline_succeeded_at' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }

      before do
        create(:ci_project_metric, project: project, first_pipeline_succeeded_at: nil)
      end

      it 'fires the internal event' do
        expect { perform }
          .to trigger_internal_events('first_pipeline_succeeded')
          .with(project: project, user: user)
          .once
      end

      it 'sets first_pipeline_succeeded_at on the existing row' do
        perform

        metric = Ci::ProjectMetric.find_by(project_id: project.id)
        expect(metric.first_pipeline_succeeded_at).to be_present
      end
    end

    context 'when pipeline has no user' do
      let(:pipeline) { create(:ci_pipeline, :success, project: project, user: nil) }

      it 'fires internal event without error' do
        expect { perform }.not_to raise_error
      end

      it 'creates a ci_project_metrics record' do
        expect { perform }.to change { Ci::ProjectMetric.count }.by(1)
      end
    end

    context 'when pipeline is not successful' do
      let(:pipeline) { create(:ci_pipeline, :failed, project: project, user: user) }

      it 'does not fire internal event' do
        expect { perform }.not_to trigger_internal_events('first_pipeline_succeeded')
      end

      it 'does not create a ci_project_metrics record' do
        expect { perform }.not_to change { Ci::ProjectMetric.count }
      end
    end

    context 'when pipeline does not exist' do
      it 'does not fire internal event' do
        expect { described_class.new.perform(non_existing_record_id) }
          .not_to trigger_internal_events('first_pipeline_succeeded')
      end
    end
  end
end
