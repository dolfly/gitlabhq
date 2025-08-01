<script>
import { GlButton, GlFormCheckbox, GlLink, GlAlert } from '@gitlab/ui';
import CiLintResults from '~/ci/pipeline_editor/components/lint/ci_lint_results.vue';
import ciLintMutation from '~/ci/pipeline_editor/graphql/mutations/ci_lint.mutation.graphql';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { CI_CONFIG_STATUS_VALID } from '~/ci/pipeline_editor/constants';

export default {
  components: {
    GlButton,
    GlFormCheckbox,
    GlLink,
    GlAlert,
    CiLintResults,
    SourceEditor,
    HelpIcon,
  },
  props: {
    lintHelpPagePath: {
      type: String,
      required: true,
    },
    pipelineSimulationHelpPagePath: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      content: '',
      loading: false,
      isValid: false,
      errors: null,
      warnings: null,
      jobs: [],
      dryRun: false,
      showingResults: false,
      apiError: null,
      isErrorDismissed: false,
    };
  },
  computed: {
    shouldShowError() {
      return this.apiError && !this.isErrorDismissed;
    },
  },
  methods: {
    async lint() {
      this.loading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: ciLintMutation,
          variables: {
            projectPath: this.projectFullPath,
            content: this.content,
            dryRun: this.dryRun,
          },
        });

        const ciConfigData = data?.ciLint?.config || {};
        const { errors, stages, warnings, status } = ciConfigData;

        this.showingResults = true;
        this.isValid = status === CI_CONFIG_STATUS_VALID;
        this.errors = errors;
        this.warnings = warnings;
        const jobs = stages.flatMap((stage) =>
          (stage.groups || []).flatMap((group) => group.jobs || []),
        );
        this.jobs = jobs;
      } catch (error) {
        this.apiError = error;
        this.isErrorDismissed = false;
      } finally {
        this.loading = false;
      }
    },
    clear() {
      this.content = '';
    },
  },
};
</script>

<template>
  <div class="row">
    <div class="col-sm-12">
      <gl-alert
        v-if="shouldShowError"
        class="gl-mb-3"
        variant="danger"
        @dismiss="isErrorDismissed = true"
        >{{ apiError }}</gl-alert
      >
      <div class="file-holder gl-mb-3">
        <div class="js-file-title file-title clearfix">
          {{ __('Contents of .gitlab-ci.yml') }}
        </div>
        <source-editor v-model="content" file-name="*.yml" />
      </div>
    </div>

    <div class="col-sm-12 gl-flex gl-justify-between">
      <div class="gl-flex gl-items-center">
        <gl-button
          class="gl-mr-4"
          :loading="loading"
          category="primary"
          variant="confirm"
          data-testid="ci-lint-validate"
          @click="lint"
          >{{ __('Validate') }}</gl-button
        >
        <gl-form-checkbox v-model="dryRun" data-testid="ci-lint-dryrun"
          >{{ __('Simulate a pipeline created for the default branch') }}
          <gl-link :href="pipelineSimulationHelpPagePath" target="_blank"><help-icon /></gl-link
        ></gl-form-checkbox>
      </div>
      <gl-button data-testid="ci-lint-clear" @click="clear">{{ __('Clear') }}</gl-button>
    </div>

    <ci-lint-results
      v-if="showingResults"
      class="col-sm-12 gl-mt-5"
      :is-valid="isValid"
      :jobs="jobs"
      :errors="errors"
      :warnings="warnings"
      :dry-run="dryRun"
      :lint-help-page-path="lintHelpPagePath"
    />
  </div>
</template>
