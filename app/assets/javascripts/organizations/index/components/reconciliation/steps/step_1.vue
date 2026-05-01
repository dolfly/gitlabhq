<script>
import { GlAvatarLabeled, GlCard } from '@gitlab/ui';
import illustrationUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-organizations-add-md.svg?url';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep1',
  AVATAR_SHAPE_OPTION_RECT,
  illustrationUrl,
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
  methods: {
    getIdFromGraphQLId,
  },
};
</script>

<template>
  <base-step
    :title="s__('Organization|Activate your Organizations')"
    :illustration="$options.illustrationUrl"
  >
    <template #description>
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
    </template>
    <div class="gl-p-2">
      <div class="-gl-m-2 gl-flex gl-flex-wrap gl-pb-4">
        <div
          v-for="organization in organizations"
          :key="organization.id"
          class="gl-w-1/2 gl-p-2 first:gl-ml-auto last:gl-mr-auto @lg:gl-w-1/3"
        >
          <gl-card class="gl-h-full" body-class="gl-bg-transparent">
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
      </div>
    </div>
  </base-step>
</template>
