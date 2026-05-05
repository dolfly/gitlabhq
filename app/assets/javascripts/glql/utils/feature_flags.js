export const glqlTypescriptFeatureFlagEnabled = () => {
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('glqlTypescript') === 'false') {
    return false;
  }

  return Boolean(gon.features?.glqlTypescript);
};

export const glqlCodeSuggestionAnalyticsAggregationEnabled = () => {
  return Boolean(gon.features?.glqlCodeSuggestionAnalyticsAggregation);
};

export const glqlFeatureFlags = () => ({
  glqlWorkItems: true,
  glqlTypescript: glqlTypescriptFeatureFlagEnabled(),
  glqlCodeSuggestions: glqlCodeSuggestionAnalyticsAggregationEnabled(),
});
