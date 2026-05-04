# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/registrations/profiles/new', feature_category: :onboarding do
  it 'renders the page heading' do
    render

    expect(rendered).to have_css('h2', text: 'Set up your profile')
  end
end
