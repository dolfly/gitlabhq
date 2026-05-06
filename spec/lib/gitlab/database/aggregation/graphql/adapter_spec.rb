# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::Graphql::Adapter, feature_category: :database do
  describe '.parent_context_name' do
    it 'converts name to camelCase' do
      expect(described_class.types_prefix('my_engine')).to eq('MyEngine')
      expect(described_class.types_prefix('engine')).to eq('Engine')
      expect(described_class.types_prefix(:my_engine)).to eq('MyEngine')
      expect(described_class.types_prefix('MY_ENGINE')).to eq('MyEngine')
    end
  end

  describe '.graphql_type' do
    it 'returns corresponding GraphQL types' do
      expect(described_class.graphql_type(:string)).to eq(::GraphQL::Types::String)
      expect(described_class.graphql_type(:integer)).to eq(::GraphQL::Types::Int)
      expect(described_class.graphql_type(:boolean)).to eq(::GraphQL::Types::Boolean)
      expect(described_class.graphql_type(:float)).to eq(::GraphQL::Types::Float)
      expect(described_class.graphql_type(:date)).to eq(::Types::DateType)
      expect(described_class.graphql_type(:datetime)).to eq(::Types::TimeType)
    end
  end

  describe '.each_filter_argument' do
    let(:exact_match_filter) do
      Gitlab::Database::Aggregation::ClickHouse::ExactMatchFilter.new(
        :status, :string
      )
    end

    let(:range_filter) do
      Gitlab::Database::Aggregation::ClickHouse::RangeFilter.new(
        :created_at, :datetime
      )
    end

    let(:metric_exact_match_filter) do
      Gitlab::Database::Aggregation::ClickHouse::MetricExactMatchFilter.new(
        :session_count, :integer
      )
    end

    let(:metric_range_filter) do
      Gitlab::Database::Aggregation::ClickHouse::MetricRangeFilter.new(
        :session_duration, :integer
      )
    end

    context 'with multiple filters' do
      it 'yields arguments for all filters' do
        filters = [exact_match_filter, range_filter]
        arguments = []

        described_class.each_filter_argument(filters) do |identifier, type, options|
          arguments << [identifier, type, options]
        end

        expect(arguments.size).to eq(3)
        expect(arguments.map(&:first)).to eq([:status, :created_at_from, :created_at_to])
      end
    end

    context 'with metric filters' do
      it 'skips metric filters' do
        filters = [exact_match_filter, metric_exact_match_filter, metric_range_filter]
        arguments = []

        described_class.each_filter_argument(filters) do |identifier, type, options|
          arguments << [identifier, type, options]
        end

        expect(arguments.map(&:first)).to eq([:status])
      end
    end
  end

  describe '.arguments_to_filters' do
    let(:engine_class) do
      exact_match = Gitlab::Database::Aggregation::ClickHouse::ExactMatchFilter.new(:status, :string)
      metric_exact_match = Gitlab::Database::Aggregation::ClickHouse::MetricExactMatchFilter.new(
        :session_count, :integer
      )

      Class.new do
        define_singleton_method(:filters) { [exact_match, metric_exact_match] }
      end
    end

    it 'skips metric filters even if matching arguments are provided' do
      arguments = { status: %w[active], session_count: [1, 2, 3] }

      expect(described_class.arguments_to_filters(engine_class, arguments))
        .to contain_exactly(identifier: :status, values: %w[active])
    end
  end
end
