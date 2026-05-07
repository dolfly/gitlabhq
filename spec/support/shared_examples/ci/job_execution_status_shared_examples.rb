# frozen_string_literal: true

RSpec.shared_examples 'job_execution_status field' do |resource_type|
  let(:entity_key) { :"#{resource_type}_entity" }

  shared_examples 'for job_execution_status field' do
    context "when #{resource_type} has no running builds" do
      it 'returns :idle' do
        expect(send(entity_key)[:job_execution_status]).to eq(:idle)
      end
    end

    context "when #{resource_type} has running builds" do
      before do
        create(:ci_build, :picked, resource_type => send(resource_type))
      end

      it 'returns :active' do
        expect(send(entity_key)[:job_execution_status]).to eq(:active)
      end
    end

    context "when #{resource_type} does not exist" do
      let(resource_type) { nil }

      it 'returns nil and does not call lazy_job_execution_status' do
        expect(entity).not_to receive(:lazy_job_execution_status)
        expect(send(entity_key)).to be_nil
      end
    end
  end

  it_behaves_like 'for job_execution_status field'

  # Remove with FF `ci_read_job_execution_status_from_running_builds`
  context "when #{resource_type} has only canceling builds" do
    before do
      create(:ci_build, :canceling, resource_type => send(resource_type))
    end

    it 'returns :idle' do
      expect(send(entity_key)[:job_execution_status]).to eq(:idle)
    end
  end

  context 'when FF `ci_read_job_execution_status_from_running_builds` is disabled' do
    before do
      stub_feature_flags(ci_read_job_execution_status_from_running_builds: false)
    end

    it_behaves_like 'for job_execution_status field'

    context "when #{resource_type} has only canceling builds" do
      before do
        create(:ci_build, :canceling, resource_type => send(resource_type))
      end

      it 'returns :active' do
        expect(send(entity_key)[:job_execution_status]).to eq(:active)
      end
    end
  end
end
