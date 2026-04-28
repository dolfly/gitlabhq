<script>
import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep1',
  AVATAR_SHAPE_OPTION_RECT,
  components: {
    BaseStep,
    GlAvatarLabeled,
    GlCard,
    HelpPageLink,
  },
  props: {
    organizations: {
      type: Array,
      required: true,
    },
  },
  emits: ['next', 'prev'],
  methods: {
    getIdFromGraphQLId,
  },
};
</script>

<template>
  <base-step
    :title="s__('Organization|Activate your Organizations')"
    @next="$emit('next')"
    @prev="$emit('prev')"
  >
    <p>
      {{
        s__(
          "Organization|We'll create one Organization per top-level group. You can reassign groups between them in the next step.",
        )
      }}
    </p>

    <p>
      <help-page-link href="user/organization/_index.md">{{
        s__('Organization|Learn how Organizations work')
      }}</help-page-link>
    </p>

    <div class="gl-mb-4 gl-grid gl-grid-cols-3 gl-gap-4">
      <gl-card
        v-for="organization in organizations"
        :key="organization.id"
        body-class="gl-bg-transparent"
      >
        <gl-avatar-labeled
          :label="organization.name"
          :entity-id="getIdFromGraphQLId(organization.id)"
          :entity-name="organization.name"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          :size="32"
          :src="organization.avatarUrl"
          class="gl-flex"
        />
      </gl-card>
    </div>
  </base-step>
</template>
