<script>
import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import Draggable from '~/lib/utils/vue3compat/draggable_compat.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import OrganizationGroupCard from '../organization_group_card.vue';
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep2',
  AVATAR_SHAPE_OPTION_RECT,
  draggableGroupName: 'organizationGroups',
  components: {
    BaseStep,
    GlCard,
    GlAvatarLabeled,
    OrganizationGroupCard,
    Draggable,
  },
  props: {
    organizations: {
      type: Array,
      required: true,
    },
  },
  emits: ['update'],
  data() {
    return {
      pendingChanges: {},
    };
  },
  methods: {
    getIdFromGraphQLId,
    onDraggableInput(changedOrganization, groups) {
      this.pendingChanges[changedOrganization.id] = groups;
    },
    onDraggableEnd() {
      const updatedOrganizations = this.organizations.map((organization) => {
        const pendingChange = this.pendingChanges[organization.id];

        if (!pendingChange) {
          return organization;
        }

        return {
          ...organization,
          groups: {
            ...organization.groups,
            nodes: pendingChange,
          },
        };
      });

      this.pendingChanges = {};

      this.$emit('update', updatedOrganizations);
    },
  },
};
</script>

<template>
  <base-step :title="s__('Organization|Assign top-level groups')">
    <template #description>
      <p>
        {{
          s__(
            'Organization|Drag groups between Organizations to set up your structure. Most companies only need one.',
          )
        }}
      </p>
    </template>

    <div class="gl-p-2">
      <div class="-gl-m-2 gl-flex gl-flex-wrap gl-pb-4">
        <div
          v-for="organization in organizations"
          :key="organization.id"
          class="gl-w-1/2 gl-p-2 first:gl-ml-auto last:gl-mr-auto @lg:gl-w-1/3"
        >
          <gl-card class="gl-h-full" body-class="gl-bg-transparent">
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
            <div class="gl-relative gl-h-full">
              <draggable
                class="organizations-reconciliation-draggable gl-flex gl-min-h-11 gl-flex-col gl-gap-4"
                chosen-class="organizations-reconciliation-draggable-chosen"
                :value="organization.groups.nodes"
                :group="$options.draggableGroupName"
                item-key="id"
                :fallback-on-body="true"
                :force-fallback="true"
                @input="onDraggableInput(organization, $event)"
                @end="onDraggableEnd"
              >
                <organization-group-card
                  v-for="group in organization.groups.nodes"
                  :key="group.id"
                  :group="group"
                  class="gl-select-none hover:gl-cursor-grab hover:gl-shadow-md"
                />
              </draggable>
              <div
                class="organizations-reconciliation-draggable-empty-state gl-border-secondary gl-pointer-events-none gl-absolute gl-flex gl-h-11 gl-w-full gl-items-center gl-justify-center gl-rounded-md gl-border-dashed gl-border-strong"
              >
                <p class="gl-m-0 gl-text-secondary">{{ s__('Organization|Drop groups here') }}</p>
              </div>
            </div>
          </gl-card>
        </div>
      </div>
    </div>
  </base-step>
</template>
