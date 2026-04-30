<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'DynamicPanel',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  provide() {
    return { panelHeadingTag: 'h2' };
  },
  props: {
    /**
     * Text to display in the panel header. The header slot takes precedence.
     */
    header: {
      type: String,
      required: false,
      default: null,
    },
  },
  i18n: {
    openTooltipText: __('Open in full page'),
    closePanelText: __('Close panel'),
  },
  emits: ['close'],
};
</script>

<template>
  <div class="paneled-view contextual-panel !gl-w-full">
    <div class="panel-header">
      <div class="panel-header-inner">
        <slot name="header">
          <span class="panel-header-inner-text">{{ header }}</span>
        </slot>
        <div class="panel-header-inner-actions">
          <gl-button
            v-gl-tooltip.bottom
            category="tertiary"
            icon="close"
            size="small"
            :aria-label="$options.i18n.closePanelText"
            :title="$options.i18n.closePanelText"
            @click="$emit('close')"
          />
        </div>
      </div>
    </div>
    <div class="panel-content">
      <div class="panel-content-inner js-dynamic-panel-inner">
        <div class="container-fluid">
          <div class="content gl-pb-3 gl-@container/panel">
            <slot></slot>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
