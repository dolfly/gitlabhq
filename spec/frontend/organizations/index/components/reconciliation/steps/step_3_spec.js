import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Step3 from '~/organizations/index/components/reconciliation/steps/step_3.vue';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';
import { DEFAULT_ORGANIZATION_ID } from '~/organizations/shared/constants';
import OrganizationGroupCard from '~/organizations/index/components/reconciliation/organization_group_card.vue';
import {
  mockOrganizations,
  organizationWithGroups,
  organizationsWithoutGroups,
} from '../mock_data';

describe('ReconciliationStep3', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(Step3, {
      propsData: {
        organizations: mockOrganizations,
        ...props,
      },
      stubs: {
        BaseStep,
        GlCard,
      },
    });
  };

  const findBaseStep = () => wrapper.findComponent(BaseStep);
  const findAllCards = () => wrapper.findAllComponents(GlCard);
  const findRetainedSection = () => wrapper.findByTestId('retained-organizations-section');
  const findDeletedSection = () => wrapper.findByTestId('deleted-organizations-section');
  const findAllGroupCards = () => wrapper.findAllComponents(OrganizationGroupCard);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders step title', () => {
      expect(findBaseStep().props('title')).toBe('Organization summary');
    });

    it('renders step description', () => {
      expect(
        wrapper
          .findByText("Here's your final structure. Activate when you're happy with it.")
          .exists(),
      ).toBe(true);
    });

    describe('retained organizations section', () => {
      it('renders section heading', () => {
        expect(wrapper.findByText('Your new structure').exists()).toBe(true);
      });

      it('renders a card for each organization with groups', () => {
        const retainedOrgs = mockOrganizations.filter((org) => org.groups.nodes.length > 0);

        expect(findAllCards()).toHaveLength(mockOrganizations.length);
        expect(retainedOrgs).toHaveLength(1);
      });

      it('renders organization labeled avatar in card header', () => {
        const card = findAllCards().at(0);

        expect(card.findComponent(GlAvatarLabeled).props()).toMatchObject({
          label: organizationWithGroups.name,
          entityName: organizationWithGroups.name,
          src: organizationWithGroups.avatarUrl,
        });
      });

      describe('group cards', () => {
        const groups = organizationWithGroups.groups.nodes;

        it('renders an organization group card for each group', () => {
          expect(findAllGroupCards()).toHaveLength(groups.length);
        });

        it('passes group prop to organization group card', () => {
          expect(findAllGroupCards().at(0).props('group')).toEqual(groups[0]);
        });
      });
    });

    describe('to be deleted organizations section', () => {
      it('renders section heading', () => {
        expect(wrapper.findByText('These Organizations will be deleted').exists()).toBe(true);
      });

      it('renders a card for each organization without groups', () => {
        const deletedCards = findAllCards().wrappers.slice(-organizationsWithoutGroups.length);

        deletedCards.forEach((card, index) => {
          expect(card.findComponent(GlAvatarLabeled).props('label')).toBe(
            organizationsWithoutGroups[index].name,
          );
        });
      });
    });
  });

  describe('when all organizations have groups', () => {
    const allWithGroups = mockOrganizations.map((org) => ({
      ...org,
      groups: {
        ...org.groups,
        nodes: org.groups.nodes.length
          ? org.groups.nodes
          : [
              {
                id: 'fake',
                fullName: 'Fake',
                visibility: 'public',
                projectsCount: 0,
                groupMembersCount: 0,
                descendantGroupsCount: 0,
              },
            ],
      },
    }));

    beforeEach(() => {
      createComponent({ props: { organizations: allWithGroups } });
    });

    it('does render retained section', () => {
      expect(findRetainedSection().exists()).toBe(true);
    });

    it('does not render deleted section', () => {
      expect(findDeletedSection().exists()).toBe(false);
    });
  });

  describe('when no organizations have groups', () => {
    const allEmpty = mockOrganizations.map((org) => ({
      ...org,
      groups: { ...org.groups, nodes: [] },
    }));

    beforeEach(() => {
      createComponent({ props: { organizations: allEmpty } });
    });

    it('does not render retained section', () => {
      expect(findRetainedSection().exists()).toBe(false);
    });

    it('does render deleted section', () => {
      expect(findDeletedSection().exists()).toBe(true);
    });
  });

  describe('default organization', () => {
    const defaultOrg = {
      id: `gid://gitlab/Organizations::Organization/${DEFAULT_ORGANIZATION_ID}`,
      name: 'Default',
      avatarUrl: null,
      groups: { nodes: [] },
    };

    it('excludes the default organization from the deleted organizations list', () => {
      createComponent({ props: { organizations: [defaultOrg] } });

      expect(findDeletedSection().exists()).toBe(false);
    });
  });
});
