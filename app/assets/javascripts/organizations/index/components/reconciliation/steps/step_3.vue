<script>
import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import OrganizationGroupCard from '../organization_group_card.vue';
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep3',
  AVATAR_SHAPE_OPTION_RECT,
  components: {
    BaseStep,
    GlAvatarLabeled,
    GlCard,
    OrganizationGroupCard,
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
            <organization-group-card
              v-for="group in organization.groups.nodes"
              :key="group.id"
              :group="group"
            />
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
