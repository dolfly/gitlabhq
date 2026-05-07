# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::SchemaCache::Table, feature_category: :database do
  let(:column_id) do
    ClickHouse::SchemaCache::Column.new(
      name: 'id', type: 'UInt64', position: 1,
      default_kind: nil, default_expression: nil, comment: nil, compression_codec: nil,
      is_in_partition_key: false, is_in_sorting_key: true,
      is_in_primary_key: true, is_in_sampling_key: false
    )
  end

  let(:column_name) do
    ClickHouse::SchemaCache::Column.new(
      name: 'name', type: 'String', position: 2,
      default_kind: nil, default_expression: nil, comment: nil, compression_codec: nil,
      is_in_partition_key: false, is_in_sorting_key: false,
      is_in_primary_key: false, is_in_sampling_key: false
    )
  end

  let(:table) do
    described_class.new(
      name: 'users',
      engine: 'MergeTree',
      engine_full: 'MergeTree() ORDER BY id SETTINGS index_granularity = 8192',
      partition_key: '',
      primary_key: 'id, name',
      sorting_key: 'id',
      sampling_key: '',
      settings: { 'index_granularity' => '8192' },
      columns: [column_id, column_name]
    )
  end

  it 'exposes attributes' do
    expect(table.name).to eq('users')
    expect(table.engine).to eq('MergeTree')
    expect(table.settings).to eq('index_granularity' => '8192')
    expect(table.columns).to contain_exactly(column_id, column_name)
  end

  describe '#primary_key' do
    it 'returns column objects for the parsed key' do
      expect(table.primary_key).to eq([column_id, column_name])
    end

    it 'returns the raw string for parts that do not reference a column' do
      expression_table = described_class.new(
        name: 'events', engine: 'MergeTree', engine_full: '',
        partition_key: '', primary_key: 'cityHash64(user_id), id', sorting_key: 'id',
        sampling_key: '', settings: {}, columns: [column_id]
      )
      expect(expression_table.primary_key).to eq(['cityHash64(user_id)', column_id])
    end

    it 'does not split inside parenthesized expressions or quoted strings' do
      nested_table = described_class.new(
        name: 'events', engine: 'MergeTree', engine_full: '',
        partition_key: '',
        primary_key: "tuple(a, b), 'x, y', id",
        sorting_key: 'id',
        sampling_key: '', settings: {}, columns: [column_id]
      )
      expect(nested_table.primary_key).to eq(['tuple(a, b)', "'x, y'", column_id])
    end

    it 'returns an empty array when blank' do
      blank_table = described_class.new(
        name: 'users', engine: 'MergeTree', engine_full: '',
        partition_key: '', primary_key: '', sorting_key: '', sampling_key: '',
        settings: {}, columns: [column_id]
      )
      expect(blank_table.primary_key).to eq([])
    end
  end

  describe '#sorting_key' do
    it 'returns column objects for the parsed key' do
      expect(table.sorting_key).to eq([column_id])
    end
  end

  describe '#column' do
    it 'returns the column by name' do
      expect(table.column('id')).to eq(column_id)
      expect(table.column(:name)).to eq(column_name)
    end

    it 'returns nil for unknown columns' do
      expect(table.column('missing')).to be_nil
    end
  end

  describe '#column_names' do
    it 'returns the names of all columns in order' do
      expect(table.column_names).to eq(%w[id name])
    end
  end

  describe '#to_h' do
    it 'serializes a hash representation suitable for YAML dump' do
      hash = table.to_h

      expect(hash['name']).to eq('users')
      expect(hash['primary_key']).to eq('id, name')
      expect(hash['sorting_key']).to eq('id')
      expect(hash['settings']).to eq('index_granularity' => '8192')
      expect(hash['columns'].first).to include('name' => 'id', 'type' => 'UInt64')
    end
  end
end
