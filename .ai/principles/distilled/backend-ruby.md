---
source_checksum: 2b22433c4282c567
distilled_at_sha: 9ab16c7588f7d32fdb6d509a70bae72309346826
---
<!-- Auto-generated from docs.gitlab.com by scripts/ai/sync_principles.rb — do not edit manually -->

# Backend Ruby/Rails Principles

## Checklist

### Ruby Style

- Order methods by level of abstraction (high-level orchestrator methods before helper methods) within each visibility section.
- DO NOT nest beyond two levels of method calls in the stepdown pattern; refactor into separate classes if needed.
- Use `attr_reader` for public attributes only when accessed outside the class; maintain consistency for internal access.
- Separate code with newlines only to group related logic together; add a newline before blocks.
- DO NOT add a newline when a code block starts or ends right inside another code block.
- Use `for_` prefix for scopes filtering by `belongs_to` associations (e.g., `scope :for_project`).
- Use `with_` prefix for scopes using `joins`, `includes`, or filtering by `has_one`/`has_many`/boolean conditions.
- Use `order_by_` prefix for scopes that apply `order`.
- Freeze constants (`CONSTANT = 'value'.freeze`).
- DO NOT call application logic (database queries, service calls, I18n helpers) when defining class-level constants; use a method instead so the logic runs at call time.

### ActiveRecord / Rails

- DO NOT add new lifecycle logic via ActiveRecord callbacks; put it in a service class instead.
- Use callbacks only when no superior alternative exists (e.g., overriding dependency callbacks, incrementing cache counts, data normalization on the current model only).
- DO NOT override `has_many through:` or `has_one through:` associations; overriding changes `destroy()` behavior and can cause data loss.
- DO NOT put business logic in controllers; use service objects.
- DO NOT open database connections or issue queries from Rails initializers.
- DO NOT issue database queries in routes.

### JSON

- Use `Gitlab::Json` in place of all calls to the default `JSON` class, `.to_json`, and similar methods.
- Use `Gitlab::Json::LimitedEncoder` when JSON output size must be bounded.

### Logging

- DO NOT use `Rails.logger`; use a structured JSON logger instead.
- DO NOT use `$stdout.puts`, `$stderr.puts`, `$stdout.print`, `$stderr.print`, or equivalent `STDOUT`/`STDERR` calls in application code.
- Use a subclass of `Gitlab::JsonLogger` for new log files; call `exclude_context!` if the logger is used outside of a request context.
- Pass log messages as key-value hashes, not interpolated strings (e.g., `logger.info(message: "...", project_id: id)`).
- Ensure field value types are consistent across all log calls for the same field key; DO NOT mix types (e.g., integer vs. string for the same field).
- Ensure list elements in log fields are all the same type.
- Include a `class` attribute in structured log payloads; use `Gitlab::Loggable` and `build_structured_payload` to add it automatically.
- Log durations in seconds as a float with microsecond precision; suffix the key with `_s` and include `duration` in the key name (e.g., `view_duration_s`).
- DO NOT manually log exceptions; use `Gitlab::ErrorTracking.track_exception` or `Gitlab::ErrorTracking.track_and_raise_exception` with additional context parameters.
- DO NOT increase overall log volume by more than 10% when adding new log messages.
- Log deprecation notices only in the development environment if the expected volume is large.

### Log Field Standards

- Log fields should be defined within the LabKit Ruby Fields module.
- Common logging fields imported from `labkit-ruby` `lib/labkit/fields.rb`.
- New fields added to log messages must not be dynamically generated.
- Follow Field Standardisation Guidelines for observability.

### Internationalization (i18n)

- Wrap all user-visible strings in Ruby/HAML with `_()`, `s_()`, or `n_()` helpers; use `__()`, `s__()`, `n__()` in JavaScript/Vue.
- DO NOT translate strings at class or module load time (e.g., in constants or memoized class methods); keep translations dynamic by calling helpers inside instance/class methods.
- DO NOT split sentences across multiple translation calls; externalize the full sentence with interpolation placeholders.
- DO NOT include HTML directly in translation strings; use `safe_format` with `tag_pair` in Ruby/HAML or `GlSprintf` in Vue.
- DO NOT call `downcase` or `toLocaleLowerCase()` on translatable strings; let translators control casing.
- Add a namespace (PascalCase, followed by `|`) to all UI strings to provide translator context; prefer granular subcategories over broad ones.
- Pass only string literals to translation helpers; DO NOT pass variables, function calls, or interpolated strings.
- Use `%{named}` placeholders (not `%d` positional) in singular strings to allow natural translation.
- Use `n_`/`n__` only to select between plural forms of the same string, not to switch between entirely different strings.
- Add errors to `:base` with a complete sentence rather than to a specific attribute when the message is a full sentence, to avoid Rails prepending the humanized attribute name.
- Update `locale/gitlab.pot` by running `tooling/bin/gettext_extractor locale/gitlab.pot` before pushing changes to translated strings.
- In RSpec, use the same externalizing helper in expectations (e.g., `have_content(_('...'))`); DO NOT hard-code translated strings.
- In Jest, DO NOT wrap expected strings in `__()` — externalization is mocked and expectations should use plain string literals.

### Redis

- Ensure Redis keys are globally unique across all Redis categories/instances.
- Use immutable identifiers (e.g., project ID, not full path) in Redis key names.
- Enclose the changeable parts of keys in curly braces `{}` when multiple keys must reside on the same Redis shard (hash-tags for Redis Cluster compatibility).
- Use `Gitlab::Redis::Cache` only for truly ephemeral, regenerable data; always set a TTL.
- Use `Gitlab::Redis::SharedState` for data that must persist until its expiration; always set a TTL.
- DO NOT use `Rails.cache` for data that must be reliably persisted; use `Gitlab::Redis::SharedState` instead.
- DO NOT use query parameters in endpoints where ETag caching is enabled; include all parameters in the request path.

### Routing

- Place every group route under the `/-/` scope.
- Place every project route under the `/-/` scope, except where a Git client or other external software requires otherwise.
- Use organization-scoped routes (`/o/:organization_path/*path`) for organization-level resources.
- DO NOT change an existing URL without providing a redirect; support both old and new URLs for at least one major release for script-facing URLs, and add a redirect for user-facing URLs until the next major release.
- Use `Gitlab::Routing.redirect_legacy_paths` when adding `/-/` scope to previously unscoped routes.

### Code Comments

- Focus comments on the "why" (rationale, constraints, edge cases), not the "what" or "how".
- Add a link to a tracking issue in any comment describing a follow-up action or technical debt.
- Use YARD syntax (`@param`, `@return`) when documenting method arguments or return values.
- Annotate methods whose return value should not be used with `@return [void]` and explicitly `return nil` at the end.

### Gotchas

- DO NOT read files from `app/assets` in application code; use `lib/assets` for assets that must be accessed by application code but not served directly.
- DO NOT assert against the absolute value of a sequence-generated factory attribute in specs; set the attribute explicitly with a value that does not match the sequence pattern.
- DO NOT use `expect_any_instance_of` or `allow_any_instance_of` in RSpec; use `expect_next_instance_of`, `allow_next_instance_of`, `expect_next_found_instance_of`, or `allow_next_found_instance_of` instead.
- Use `expect_next_found_instance_of` / `allow_next_found_instance_of` (not `expect_next_instance_of`) for objects returned by ActiveRecord query/finder methods.
- DO NOT `rescue Exception`; rescue specific exception classes.
- DO NOT use inline JavaScript in Haml views (`:javascript` filter).

### RuboCop

- DO NOT disable RuboCop rules inline without providing a reason as a code comment on the same line.
- Use `rubocop:todo` (not `rubocop:disable`) for temporary inline disables, and link the follow-up issue or epic.
- Include RDoc-style docs with "good" and "bad" examples when creating new internal RuboCop cops.

## Authoritative sources

For the full picture, see:

- doc/development/backend/ruby_style_guide.md
- doc/development/gotchas.md
- doc/development/logging.md
- doc/development/json.md
- doc/development/i18n/externalization.md
- doc/development/redis.md
- doc/development/polling.md
- doc/development/routing.md
- doc/development/rails_initializers.md
- doc/development/code_comments.md
- doc/development/rubocop_development_guide.md

