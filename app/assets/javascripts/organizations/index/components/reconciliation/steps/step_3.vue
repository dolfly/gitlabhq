<script>
import { GlAvatarLabeled, GlCard, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '~/visibility_level/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep3',
  AVATAR_SHAPE_OPTION_RECT,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    BaseStep,
    GlAvatarLabeled,
    GlCard,
    GlIcon,
    ListItemStat,
  },
  props: {
    organizations: {
      type: Array,
      required: true,
    },
  },
  computed: {
    retainedOrganizations() {
      return this.organizations.filter((org) => org.groups.nodes.length > 0);
    },
    deletedOrganizations() {
      return this.organizations.filter((org) => org.groups.nodes.length === 0);
    },
  },
  methods: {
    getIdFromGraphQLId,
    numberToMetricPrefix,
    visibilityIcon(visibility) {
      return VISIBILITY_TYPE_ICON[visibility];
    },
    visibilityTooltip(visibility) {
      return GROUP_VISIBILITY_TYPE[visibility];
    },
  },
};
</script>

<template>
  <base-step :title="s__('Organization|Organization summary')">
    <template #description>
      <p>
        {{ s__("Organization|Here's your final structure. Activate when you're happy with it.") }}
      </p>
    </template>

    <div
      v-if="retainedOrganizations.length"
      data-testid="retained-organizations-section"
      class="gl-mb-6"
    >
      <h5 class="gl-heading-5">{{ s__('Organization|Your new structure') }}</h5>
      <div class="gl-flex gl-flex-col gl-gap-4">
        <gl-card
          v-for="organization in retainedOrganizations"
          :key="organization.id"
          body-class="gl-bg-transparent"
        >
          <template #header>
            <gl-avatar-labeled
              class="gl-flex"
              :label="organization.name"
              :entity-id="getIdFromGraphQLId(organization.id)"
              :entity-name="organization.name"
              :shape="$options.AVATAR_SHAPE_OPTION_RECT"
              :size="32"
              :src="organization.avatarUrl"
            />
          </template>
          <div class="gl-grid gl-grid-cols-2 gl-gap-4 md:gl-grid-cols-3">
            <div
              v-for="group in organization.groups.nodes"
              :key="group.id"
              class="gl-rounded-xl gl-bg-white gl-p-4"
              data-testid="organization-group"
            >
              <div class="gl-flex gl-items-center gl-gap-3">
                <gl-icon class="gl-shrink-0" variant="subtle" name="group" />
                <div class="gl-break-anywhere">
                  <span class="gl-font-bold">{{ group.fullName }}</span
                  ><gl-icon
                    v-gl-tooltip="visibilityTooltip(group.visibility)"
                    :name="visibilityIcon(group.visibility)"
                    class="gl-ml-2"
                    variant="subtle"
                    data-testid="group-visibility"
                  />
                </div>
              </div>
              <div class="gl-mt-3 gl-flex gl-items-center gl-gap-x-3 gl-pl-6">
                <list-item-stat
                  :tooltip-text="__('Subgroups')"
                  icon-name="subgroup"
                  :stat="numberToMetricPrefix(group.descendantGroupsCount)"
                />
                <list-item-stat
                  :tooltip-text="__('Projects')"
                  icon-name="project"
                  :stat="numberToMetricPrefix(group.projectsCount)"
                />
                <list-item-stat
                  :tooltip-text="__('Direct members')"
                  icon-name="users"
                  :stat="numberToMetricPrefix(group.groupMembersCount)"
                />
              </div>
            </div>
          </div>
        </gl-card>
      </div>
    </div>

    <div v-if="deletedOrganizations.length" data-testid="deleted-organizations-section">
      <h5 class="gl-heading-5">{{ s__('Organization|These Organizations will be deleted') }}</h5>
      <div class="gl-flex gl-flex-col gl-gap-4">
        <gl-card
          v-for="organization in deletedOrganizations"
          :key="organization.id"
          body-class="gl-bg-transparent"
        >
          <gl-avatar-labeled
            class="gl-flex"
            :label="organization.name"
            :entity-id="getIdFromGraphQLId(organization.id)"
            :entity-name="organization.name"
            :shape="$options.AVATAR_SHAPE_OPTION_RECT"
            :size="32"
            :src="organization.avatarUrl"
          />
        </gl-card>
      </div>
    </div>
  </base-step>
</template>
