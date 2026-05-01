<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'PanelActions',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    closePanelText: __('Close panel'),
  },
  emits: ['close'],
};
</script>

<template>
  <div class="panel-header-inner-actions">
    <slot></slot>

    <gl-button
      v-gl-tooltip.bottom="$options.i18n.closePanelText"
      category="tertiary"
      icon="close"
      size="small"
      :aria-label="$options.i18n.closePanelText"
      @click="$emit('close')"
    />
  </div>
</template>
