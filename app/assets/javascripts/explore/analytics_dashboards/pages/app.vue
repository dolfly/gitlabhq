<script>
export default {
  name: 'ExploreAnalyticsDashboards',
  inject: {
    organizationId: {
      type: String,
      required: true,
    },
    currentUserId: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <router-view :organization-id="organizationId" :current-user-id="currentUserId" />
</template>
