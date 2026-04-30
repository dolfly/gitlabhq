<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep2',
  i18n: {
    placeholder: s__('Organization|Step 2 placeholder'),
    totalOrganizations: s__('Organization|Total Organizations: %{count}'),
  },
  components: {
    BaseStep,
    GlSprintf,
  },
  props: {
    organizations: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <base-step>
    <p>{{ $options.i18n.placeholder }}</p>
    <div data-testid="total-organizations" class="gl-my-3">
      <gl-sprintf :message="$options.i18n.totalOrganizations">
        <template #count>{{ organizations.length }}</template>
      </gl-sprintf>
    </div>
  </base-step>
</template>
