# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates settings', feature_category: :shared do
  include StubENV

  let_it_be(:admin) { create(:admin) }

  context 'application setting :admin_mode is enabled', :request_store, :enable_admin_mode do
    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      sign_in(admin)
    end

    context 'Integration page', :js do
      before do
        visit integrations_admin_application_settings_path
      end

      it 'shows integrations table',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/449030' do
        expect(page).to have_selector '[data-testid="inactive-integrations-table"]'
      end
    end

    context 'Nav bar', :js do
      it 'shows default help links in nav' do
        visit root_dashboard_path

        within_testid('super-sidebar') do
          click_on 'Help'
          expect(page).to have_link(text: 'Help', href: help_path)
          expect(page).to have_link(text: 'Support', href: 'https://support.gitlab.com')
        end
      end

      it 'shows custom support url in nav when set' do
        new_support_url = 'http://example.com/help'
        stub_application_setting(help_page_support_url: new_support_url)

        visit root_dashboard_path

        within_testid('super-sidebar') do
          click_on 'Help'
          expect(page).to have_link(text: 'Support', href: new_support_url)
        end
      end
    end
  end
end
