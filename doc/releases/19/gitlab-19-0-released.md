---
stage: Release Notes
group: Monthly Release
title: "GitLab 19.0 release notes - not yet released"
description: "Summary of features included in 19.0"
---

The following features are being delivered for GitLab 19.0.
These features are now available on GitLab.com.

<!-- Copy this template, and paste it into the doc section where it belongs:

Primary feature, Agentic Core, Scale and Deployments, or Unified DevOps and Security.

Update all the information as needed.

### Feature explanation here

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Now write 125 words or fewer to explain the value of this improvement.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."

Use present tense, and speak about "you" instead of "the user."
-->

<!-- ## Primary features

The first person to add a feature in this area, please make the title visible and delete this comment -->

## Agentic Core

### Filter exact code search results by repository

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/exact_code_search.md#syntax), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/488467)

{{< /details >}}

You can now filter exact code search results by repository. With the `repo:` syntax,
you can directly scope your search query to specific repositories or repository patterns
without having to go to individual projects.

For example, searching for `def authenticate repo:my-group/my-project` returns results
only from that repository. You can also use partial paths or patterns to match multiple repositories.

<!-- ## Scale and Deployments

The first person to add a feature in this area, please make the title visible and delete this comment -->

## Unified DevOps and Security

### Improved array support for CI/CD inputs

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/inputs/_index.md#access-individual-array-elements), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/587657)

{{< /details >}}

CI/CD inputs now have improved support for working with arrays.
Use the array index operator `[]` to access specific elements within array inputs.
This enhancement provides more flexible and powerful input interpolation capabilities in your pipeline configurations,
enabling you to reference individual array items directly without additional processing steps.

### Select multiple values for pipeline inputs

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/inputs/_index.md#array-inputs-with-options), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/566155)

{{< /details >}}

Previously, you could only select a single value when selecting input options in the UI,
limiting flexibility for pipelines with more complex options.

Now when you run a pipeline with inputs from the UI, you can select multiple values from a dropdown list
and the selected values are combined into an array, for example `["option1","option2"]`.
This makes it easy to restart services on multiple instances, build multiple Docker images,
run tests with multiple tag combinations, or perform any operation across multiple targets
in a single pipeline run.

### Secure webhooks with HMAC signing tokens

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/integrations/webhooks.md#signing-tokens), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/19367)

{{< /details >}}

The existing `X-Gitlab-Token` header sends a static secret in plain text,
making webhooks susceptible to interception and replay attacks.

You can now add a signing token to any webhook. GitLab uses
the signing token to compute an HMAC-SHA256 signature over:

- The unique webhook ID.
- The request timestamp.
- The webhook payload.

GitLab then sends the result in the `webhook-signature` header alongside
`webhook-id` and `webhook-timestamp` headers, following the
[Standard Webhooks](https://www.standardwebhooks.com/) specification.

You can recompute the signature to confirm requests genuinely came from GitLab
and that the payload has not been modified. By also validating the timestamp, you can reject replayed requests.

Thanks to [Van Anderson](https://gitlab.com/van.m.anderson) and
[Norman Debald](https://gitlab.com/Modjo85) for their community contributions!
