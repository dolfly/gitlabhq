<script>
import { DISPLAY_TYPES } from '../../constants';
import ListPresenter from './list.vue';
import TablePresenter from './table.vue';

export default {
  name: 'DataPresenter',
  components: {
    TablePresenter,
    ListPresenter,
  },
  props: {
    displayType: {
      required: true,
      type: String,
    },
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
    },
    fields: {
      required: false,
      type: Array,
      default: () => [],
    },
    loading: {
      required: false,
      type: [Boolean, Number],
      default: false,
    },
  },
  computed: {
    isList() {
      return (
        this.displayType === DISPLAY_TYPES.LIST || this.displayType === DISPLAY_TYPES.ORDERED_LIST
      );
    },
    listType() {
      return this.displayType === DISPLAY_TYPES.LIST ? 'ul' : 'ol';
    },
  },
  DISPLAY_TYPES,
};
</script>
<template>
  <table-presenter
    v-if="displayType === $options.DISPLAY_TYPES.TABLE"
    :data="data"
    :fields="fields"
    :loading="loading"
  />
  <list-presenter
    v-else-if="isList"
    :data="data"
    :fields="fields"
    :loading="loading"
    :list-type="listType"
  />
</template>
