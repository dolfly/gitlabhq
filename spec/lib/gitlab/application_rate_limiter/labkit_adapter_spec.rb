# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::LabkitAdapter,
  :clean_gitlab_redis_rate_limiting, :prometheus, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '.shadow_or_enforce?' do
    using RSpec::Parameterized::TableSyntax

    where(:scenario, :key, :threshold_override, :interval_override, :flag_on, :expected) do
      'key not handled by the adapter'             | :glql             | nil | nil | true  | false
      'threshold override forces the legacy path'  | :pipelines_create | 10  | nil | true  | false
      'interval override forces the legacy path'   | :pipelines_create | nil | 60  | true  | false
      'use_labkit flag is off'                     | :pipelines_create | nil | nil | false | false
      'handled key, no overrides, flag on'         | :pipelines_create | nil | nil | true  | true
    end

    with_them do
      before do
        stub_feature_flags(rate_limiter_use_labkit_pipelines_create: flag_on)
      end

      it 'returns the expected dispatch decision' do
        expect(
          described_class.shadow_or_enforce?(key,
            threshold_override: threshold_override,
            interval_override: interval_override)
        ).to be(expected)
      end
    end

    context 'when an override is passed' do
      let(:override_counter) { instance_double(Prometheus::Client::Counter, increment: nil) }

      before do
        stub_feature_flags(rate_limiter_use_labkit_pipelines_create: true)
        allow(Gitlab::Metrics).to receive(:counter).and_call_original
        allow(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_rate_limiter_labkit_override_total, anything, anything)
          .and_return(override_counter)
      end

      where(:threshold_override, :interval_override, :expected_kind) do
        10  | nil | :threshold
        nil | 60  | :interval
        10  | 60  | :both
      end

      with_them do
        it 'records the override kind on the counter' do
          expect(override_counter).to receive(:increment)
            .with(key: :pipelines_create, override: expected_kind)

          described_class.shadow_or_enforce?(:pipelines_create,
            threshold_override: threshold_override,
            interval_override: interval_override)
        end
      end

      it 'does not record overrides for keys the adapter does not handle' do
        expect(override_counter).not_to receive(:increment)

        described_class.shadow_or_enforce?(:glql, threshold_override: 10, interval_override: nil)
      end

      it 'does not record when no override is passed' do
        expect(override_counter).not_to receive(:increment)

        described_class.shadow_or_enforce?(:pipelines_create, threshold_override: nil, interval_override: nil)
      end
    end
  end

  describe '.enforce?' do
    it 'reflects the per-key enforce flag' do
      stub_feature_flags(rate_limiter_use_labkit_pipelines_create_enforce: false)
      expect(described_class.enforce?(:pipelines_create)).to be(false)

      stub_feature_flags(rate_limiter_use_labkit_pipelines_create_enforce: true)
      expect(described_class.enforce?(:pipelines_create)).to be(true)
    end
  end

  describe '.run!' do
    context 'when called repeatedly within a single period' do
      it 'increments the same labkit counter' do
        described_class.run!(:users_get_by_id, scope: user)
        described_class.run!(:users_get_by_id, scope: user)

        count = Gitlab::Redis::RateLimiting.with do |r|
          r.get("labkit:rl:applimiter_users_get_by_id:limit_user_lookups_by_user:user_id:#{user.id}")
        end

        expect(count.to_i).to eq(2)
      end

      it 'returns true once the threshold is exceeded' do
        threshold = 1
        allow(Gitlab::CurrentSettings.current_application_settings)
          .to receive(:users_get_by_id_limit).and_return(threshold)

        described_class.run!(:users_get_by_id, scope: user)
        result = described_class.run!(:users_get_by_id, scope: user)

        expect(result).to be(true)
      end
    end

    context 'when the labkit check errors' do
      let(:broken_result) { Labkit::RateLimit::Result.new(matched: false, error: true, action: :allow) }

      before do
        allow_next_instance_of(Labkit::RateLimit::Limiter) do |limiter|
          allow(limiter).to receive(:check).and_return(broken_result)
        end
      end

      it 'returns false and fails open' do
        expect(described_class.run!(:users_get_by_id, scope: user)).to be(false)
      end
    end

    context 'with scopes that flatten to the same identifier' do
      it 'collapses a bare model and a single-element array onto the same labkit counter' do
        described_class.run!(:notes_create, scope: user)
        described_class.run!(:notes_create, scope: [user])

        count = Gitlab::Redis::RateLimiting.with do |r|
          r.get("labkit:rl:applimiter_notes_create:limit_notes_by_user:user_id:#{user.id}")
        end

        expect(count.to_i).to eq(2)
      end
    end

    context "with labkit's Redis key shape" do
      it 'writes the count under the expected labkit key' do
        described_class.run!(:pipelines_create, scope: [project, user, 'abc123'])

        expected_key = "labkit:rl:applimiter_pipelines_create:limit_pipelines_by_project_user_sha" \
          ":project_id:#{project.id}:user_id:#{user.id}:sha:abc123"
        count = Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }

        expect(count.to_i).to eq(1)
      end

      it "fills missing characteristic values with the '_unknown_' sentinel" do
        described_class.run!(:search_rate_limit, scope: [user])

        expected_key = "labkit:rl:applimiter_search_rate_limit:limit_searches_by_user_scope" \
          ":user_id:#{user.id}:search_scope:_unknown_"
        count = Gitlab::Redis::RateLimiting.with { |r| r.get(expected_key) }

        expect(count.to_i).to eq(1)
      end
    end
  end

  describe '.record_divergence' do
    let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }

    before do
      allow(Gitlab::Metrics).to receive(:counter).and_return(counter)
    end

    it 'increments the match label when decisions agree' do
      allow(described_class).to receive(:window_boundary?).and_return(false)
      expect(counter).to receive(:increment)
        .with(key: :pipelines_create, agreement: :match, boundary: false)

      described_class.record_divergence(:pipelines_create, true, true)
    end

    it 'increments the diverge label when decisions disagree' do
      allow(described_class).to receive(:window_boundary?).and_return(false)
      expect(counter).to receive(:increment)
        .with(key: :pipelines_create, agreement: :diverge, boundary: false)

      described_class.record_divergence(:pipelines_create, true, false)
    end

    it 'tags increments inside the boundary noise window with boundary: true' do
      allow(described_class).to receive(:window_boundary?).and_return(true)
      expect(counter).to receive(:increment)
        .with(key: :pipelines_create, agreement: :diverge, boundary: true)

      described_class.record_divergence(:pipelines_create, true, false)
    end
  end
end
