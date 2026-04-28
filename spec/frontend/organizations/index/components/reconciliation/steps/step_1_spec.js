import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import organizationsForReconciliationResponse from 'test_fixtures/graphql/organizations/organizations_for_reconciliation.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Step1 from '~/organizations/index/components/reconciliation/steps/step_1.vue';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

const {
  data: {
    organizations: { nodes: mockOrganizations },
  },
} = organizationsForReconciliationResponse;

describe('ReconciliationStep1', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(Step1, {
      propsData: {
        organizations: mockOrganizations,
        ...props,
      },
    });
  };

  const findBaseStep = () => wrapper.findComponent(BaseStep);
  const findCards = () => wrapper.findAllComponents(GlCard);
  const findAvatars = () => wrapper.findAllComponents(GlAvatarLabeled);
  const findHelpPageLink = () => wrapper.findComponent(HelpPageLink);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders BaseStep with title', () => {
      expect(findBaseStep().props('title')).toBe('Activate your Organizations');
    });

    it('renders description text', () => {
      expect(wrapper.text()).toContain(
        "We'll create one Organization per top-level group. You can reassign groups between them in the next step.",
      );
    });

    it('renders help page link', () => {
      expect(findHelpPageLink().attributes('href')).toBe('user/organization/_index.md');
      expect(findHelpPageLink().text()).toBe('Learn how Organizations work');
    });

    it('renders a card for each organization', () => {
      expect(findCards()).toHaveLength(mockOrganizations.length);
    });

    it('renders organization avatar with name', () => {
      const avatar = findAvatars().at(0);

      expect(avatar.props('label')).toBe(mockOrganizations[0].name);
      expect(avatar.props('entityName')).toBe(mockOrganizations[0].name);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits next event', () => {
      findBaseStep().vm.$emit('next');

      expect(wrapper.emitted('next')).toHaveLength(1);
    });

    it('emits prev event', () => {
      findBaseStep().vm.$emit('prev');

      expect(wrapper.emitted('prev')).toHaveLength(1);
    });
  });
});
