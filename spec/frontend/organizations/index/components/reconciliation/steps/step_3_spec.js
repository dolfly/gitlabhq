import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import organizationsForReconciliationResponse from 'test_fixtures/graphql/organizations/organizations_for_reconciliation.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import Step3 from '~/organizations/index/components/reconciliation/steps/step_3.vue';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';

const {
  data: {
    organizations: { nodes: mockOrganizations },
  },
} = organizationsForReconciliationResponse;

const organizationWithGroups = mockOrganizations.find(
  (organization) => organization.groups.nodes.length,
);

const organizationsWithoutGroups = mockOrganizations.filter(
  (organization) => !organization.groups.nodes.length,
);

describe('ReconciliationStep3', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(Step3, {
      propsData: {
        organizations: mockOrganizations,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
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
  const findAllGroupCards = () => wrapper.findAllByTestId('organization-group');

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

        it('renders a group card for each group', () => {
          expect(findAllGroupCards()).toHaveLength(groups.length);
        });

        it('renders group name', () => {
          expect(wrapper.findByText(groups[0].fullName).exists()).toBe(true);
        });

        it('renders group visibility with tooltip', () => {
          const icon = wrapper.findByTestId('group-visibility');

          expect(icon.props('name')).toBe('earth');
          expect(getBinding(icon.element, 'gl-tooltip').value).toBe(
            'Public - The group and any public projects can be viewed without any authentication.',
          );
        });

        it('renders group stats', () => {
          const stats = wrapper.findAllComponents(ListItemStat);

          expect(stats.at(0).props()).toMatchObject({
            tooltipText: 'Subgroups',
            iconName: 'subgroup',
            stat: '0',
          });

          expect(stats.at(1).props()).toMatchObject({
            tooltipText: 'Projects',
            iconName: 'project',
            stat: '1',
          });

          expect(stats.at(2).props()).toMatchObject({
            tooltipText: 'Direct members',
            iconName: 'users',
            stat: '2',
          });
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
});
