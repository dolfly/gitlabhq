import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import { nextTick } from 'vue';
import Draggable from '~/lib/utils/vue3compat/draggable_compat.vue';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { stubComponent } from 'helpers/stub_component';
import Step2 from '~/organizations/index/components/reconciliation/steps/step_2.vue';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';
import {
  mockOrganizations,
  organizationWithGroupsIndex,
  organizationWithGroups,
  organizationWithoutGroupsIndex,
  organizationWithoutGroups,
} from '../mock_data';

describe('ReconciliationStep2', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(Step2, {
      propsData: {
        organizations: mockOrganizations,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        Draggable: stubComponent(Draggable),
      },
    });
  };

  const findBaseStep = () => wrapper.findComponent(BaseStep);
  const findAllCards = () => wrapper.findAllComponents(GlCard);
  const findCardAt = (index) => extendedWrapper(findAllCards().at(index));

  it('renders step title', () => {
    createComponent();

    expect(findBaseStep().props('title')).toBe('Assign top-level groups');
  });

  it('renders step description', () => {
    createComponent();

    expect(findBaseStep().text()).toContain(
      'Drag groups between Organizations to set up your structure. Most companies only need one.',
    );
  });

  it('renders a card for each organization', () => {
    createComponent();

    expect(findAllCards()).toHaveLength(mockOrganizations.length);
  });

  it('renders organization labeled avatar', () => {
    createComponent();

    const card = findCardAt(0);
    const organization = mockOrganizations[0];

    expect(card.findComponent(GlAvatarLabeled).props()).toMatchObject({
      label: organization.name,
      entityName: organization.name,
      src: organization.avatarUrl,
    });
  });

  describe('when organization has groups', () => {
    const groups = organizationWithGroups.groups.nodes;

    const findAllGroupCards = (organizationCard) =>
      organizationCard.findAllByTestId('organization-group');
    const findGroupCardAt = (organizationCard, index) =>
      extendedWrapper(findAllGroupCards(organizationCard).at(index));

    it('renders group cards', () => {
      createComponent();

      const card = findCardAt(organizationWithGroupsIndex);
      const groupCards = findAllGroupCards(card);

      expect(groupCards).toHaveLength(groups.length);
    });

    it('renders group name', () => {
      createComponent();

      const card = findCardAt(organizationWithGroupsIndex);
      const group = groups[0];
      const groupCard = findGroupCardAt(card, 0);

      expect(groupCard.text()).toContain(group.fullName);
    });

    it('renders group visibility with tooltip', () => {
      createComponent();

      const card = findCardAt(organizationWithGroupsIndex);
      const groupCard = findGroupCardAt(card, 0);
      const icon = groupCard.findByTestId('group-visibility');

      expect(groupCard.findByTestId('group-visibility').props('name')).toBe('earth');
      expect(getBinding(icon.element, 'gl-tooltip').value).toBe(
        'Public - The group and any public projects can be viewed without any authentication.',
      );
    });

    it('renders group stats', () => {
      const [group] = organizationWithGroups.groups.nodes;

      createComponent({
        props: {
          organizations: mockOrganizations.toSpliced(organizationWithGroupsIndex, 1, {
            ...organizationWithGroups,
            groups: {
              ...organizationWithGroups.groups,
              nodes: [
                {
                  ...group,
                  descendantGroupsCount: 1200,
                  projectsCount: 10500,
                  groupMembersCount: 1500000,
                },
              ],
            },
          }),
        },
      });

      const card = findCardAt(organizationWithGroupsIndex);
      const groupCard = findGroupCardAt(card, 0);
      const stats = groupCard.findAllComponents(ListItemStat);

      expect(stats.at(0).props()).toMatchObject({
        tooltipText: 'Subgroups',
        iconName: 'subgroup',
        stat: '1.2k',
      });

      expect(stats.at(1).props()).toMatchObject({
        tooltipText: 'Projects',
        iconName: 'project',
        stat: '10.5k',
      });

      expect(stats.at(2).props()).toMatchObject({
        tooltipText: 'Direct members',
        iconName: 'users',
        stat: '1.5m',
      });
    });
  });

  describe('drag and drop', () => {
    const findAllDraggableComponents = () => wrapper.findAllComponents(Draggable);

    it('renders drag and drop group for each organization', () => {
      createComponent();

      const draggableComponents = findAllDraggableComponents();

      expect(draggableComponents).toHaveLength(mockOrganizations.length);
      expect(
        draggableComponents.wrappers.every(
          (draggable) => draggable.attributes('group') === 'organizationGroups',
        ),
      ).toBe(true);
    });

    describe('when group is moved between organizations', () => {
      it('emits update event once with updated organization structure', async () => {
        createComponent();

        const draggableComponents = findAllDraggableComponents();

        const draggableWithGroups = draggableComponents.at(organizationWithGroupsIndex);
        const draggableWithoutGroups = draggableComponents.at(organizationWithoutGroupsIndex);
        const groupToMoveIndex = 0;
        const groupToMove = organizationWithGroups.groups.nodes[groupToMoveIndex];

        draggableWithGroups.vm.$emit(
          'input',
          organizationWithGroups.groups.nodes.toSpliced(groupToMoveIndex, 1),
        );
        draggableWithoutGroups.vm.$emit('input', [groupToMove]);
        draggableWithoutGroups.vm.$emit('end');

        await nextTick();

        const expectedOrganizations = mockOrganizations
          .toSpliced(organizationWithGroupsIndex, 1, {
            ...organizationWithGroups,
            groups: {
              ...organizationWithGroups.groups,
              nodes: organizationWithGroups.groups.nodes.toSpliced(groupToMoveIndex, 1),
            },
          })
          .toSpliced(organizationWithoutGroupsIndex, 1, {
            ...organizationWithoutGroups,
            groups: {
              ...organizationWithoutGroups.groups,
              nodes: [groupToMove],
            },
          });

        expect(wrapper.emitted('update')).toEqual([[expectedOrganizations]]);
      });
    });
  });
});
