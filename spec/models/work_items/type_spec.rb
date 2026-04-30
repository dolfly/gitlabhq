# frozen_string_literal: true

require 'spec_helper'

# This spec tests the legacy WorkItems::Type ActiveRecord model which is retained
# only for DB seeding and GraphQL GlobalID constant resolution.
# Type behavior is tested in spec/models/work_items/types_framework/system_defined/type_spec.rb.
RSpec.describe WorkItems::Type, feature_category: :team_planning do
  describe 'constants' do
    it 'defines TYPE_NAMES for all base types' do
      expect(described_class::TYPE_NAMES).to include(
        issue: 'Issue',
        incident: 'Incident',
        test_case: 'Test Case',
        requirement: 'Requirement',
        task: 'Task',
        objective: 'Objective',
        key_result: 'Key Result',
        epic: 'Epic',
        ticket: 'Ticket'
      )
    end

    it 'defines BASE_TYPES with name, icon_name, enum_value, and id for each type' do
      described_class::BASE_TYPES.each_value do |attrs|
        expect(attrs).to include(:name, :icon_name, :enum_value, :id)
      end
    end
  end

  describe 'enum' do
    it { is_expected.to define_enum_for(:base_type) }
  end
end
