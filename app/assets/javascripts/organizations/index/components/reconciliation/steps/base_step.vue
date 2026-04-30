<script>
import { GlIcon } from '@gitlab/ui';

export default {
  name: 'ReconciliationBaseStep',
  components: {
    GlIcon,
  },
  props: {
    icon: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div>
    <gl-icon v-if="icon" :name="icon" />
    <h4 v-if="title">{{ title }}</h4>
    <slot></slot>
  </div>
</template>
