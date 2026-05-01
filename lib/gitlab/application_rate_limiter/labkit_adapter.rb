# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    # Routes a subset of ApplicationRateLimiter checks through Labkit::RateLimit::Limiter.
    #
    # Behaviour is gated by two wip feature flags per key:
    #   - rate_limiter_use_labkit_<key>          : run the labkit path alongside legacy
    #   - rate_limiter_use_labkit_<key>_enforce  : let labkit's decision win over legacy
    #
    # The two flags produce three states:
    #
    #   use_labkit off / enforce off : only the legacy path runs.
    #   use_labkit on  / enforce off : both paths run; the legacy decision is
    #                                  returned. The shadow counter records
    #                                  whether the two paths agree.
    #   use_labkit on  / enforce on  : only the labkit path runs; its decision
    #                                  is returned.
    #
    # The legacy and labkit Redis key shapes are intentionally disjoint
    # ("application_rate_limiter:..." vs "labkit:rl:...") so both counters can
    # increment independently without interfering with each other.
    module LabkitAdapter
      # Single source of truth for the keys this adapter handles and the
      # labkit Limiter/Rule shape used for each one. Adding a key here
      # extends the dispatch from _throttled? to that key; the entry also
      # needs its two wip feature flags in config/feature_flags/wip/.
      #
      # Each entry carries everything needed to build a labkit Limiter at
      # call time: a stable Limiter name (defining the labkit Redis key
      # namespace), a descriptive Rule name, the scope characteristics, and
      # the Rule action.
      #
      # Threshold and interval are intentionally not stored here. They are
      # resolved per check from Gitlab::ApplicationRateLimiter.rate_limits so
      # application-setting overrides and test stubs propagate to the labkit
      # path. The Rule's `action:` is informational; the adapter owns the
      # enforce decision via the per-key _enforce flag.
      SUPPORTED_RATE_LIMITS = {
        pipelines_create: {
          limiter_name: 'applimiter_pipelines_create',
          rule_name: 'limit_pipelines_by_project_user_sha',
          characteristics: %i[project_id user_id sha],
          action: :block
        },
        notes_create: {
          limiter_name: 'applimiter_notes_create',
          rule_name: 'limit_notes_by_user',
          characteristics: %i[user_id],
          action: :block
        },
        search_rate_limit: {
          limiter_name: 'applimiter_search_rate_limit',
          rule_name: 'limit_searches_by_user_scope',
          characteristics: %i[user_id search_scope],
          action: :block
        },
        users_get_by_id: {
          limiter_name: 'applimiter_users_get_by_id',
          rule_name: 'limit_user_lookups_by_user',
          characteristics: %i[user_id],
          action: :block
        },
        user_sign_in: {
          limiter_name: 'applimiter_user_sign_in',
          rule_name: 'limit_signins_by_user',
          characteristics: %i[user_id],
          action: :block
        }
      }.freeze

      # Convenience alias for callers (e.g. spec_helper) that just need the
      # routed key list. Source of truth is SUPPORTED_RATE_LIMITS.
      HANDLED_KEYS = SUPPORTED_RATE_LIMITS.keys.freeze

      # Window-boundary skew between labkit's TTL and legacy's divmod-based
      # period_key produces sub-second disagreements that are not bugs. The
      # shadow counter still records these events but tags them with
      # `boundary: true` so dashboards can filter them out of "should we
      # flip enforce?" queries while keeping the data observable.
      BOUNDARY_NOISE_SECONDS = 1

      class << self
        # The Feature.enabled? calls below use a dynamic flag name keyed off the
        # handled key. Each flag is also enumerated in SUPPORTED_RATE_LIMITS
        # and has its own YAML in config/feature_flags/wip/, so a codebase
        # search for any flag name still finds it.
        #
        # Feature.current_request as the actor gives a global on/off semantic for
        # request-bound callers. For non-request callers (e.g. pipelines_create
        # invoked from a Sidekiq worker), Feature.current_request resolves to a
        # fresh per-call UUID, so percentage rollouts behave non-deterministically
        # from non-request paths. Operate these flags as fully on or fully off.

        def shadow_or_enforce?(key, threshold_override:, interval_override:)
          return false unless SUPPORTED_RATE_LIMITS.key?(key)

          if !threshold_override.nil? || !interval_override.nil?
            record_override(key, threshold_override, interval_override)
            return false
          end

          # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- flag names enumerated in SUPPORTED_RATE_LIMITS and config/feature_flags/wip/
          Feature.enabled?(:"rate_limiter_use_labkit_#{key}", Feature.current_request, type: :wip)
          # rubocop:enable Gitlab/FeatureFlagKeyDynamic
        end

        # Whether labkit's decision should win over the legacy decision.
        def enforce?(key)
          return false unless SUPPORTED_RATE_LIMITS.key?(key)

          # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- flag names enumerated in SUPPORTED_RATE_LIMITS and config/feature_flags/wip/
          Feature.enabled?(:"rate_limiter_use_labkit_#{key}_enforce", Feature.current_request, type: :wip)
          # rubocop:enable Gitlab/FeatureFlagKeyDynamic
        end

        # Always increments the labkit counter and returns labkit's boolean
        # decision (whether the request should be blocked, ignoring whether
        # enforcement is on).
        #
        # @return [Boolean] labkit's decision (exceeded?)
        def run!(key, scope:)
          spec = SUPPORTED_RATE_LIMITS.fetch(key)
          rule = build_rule(key, spec)
          limiter = ::Labkit::RateLimit::Limiter.new(
            name: spec[:limiter_name],
            rules: [rule],
            redis: ::Gitlab::Redis::RateLimiting,
            logger: ::Gitlab::AppLogger
          )
          result = limiter.check(identifier_for(rule, scope))

          return false if result.error?

          result.exceeded?
        end

        # Compares labkit's decision against the legacy path's decision and
        # increments a Prometheus counter labelled by agreement and by whether
        # the check landed within BOUNDARY_NOISE_SECONDS of a window edge.
        # Boundary-edge events are tagged rather than dropped so dashboards
        # can filter them out of go/no-go queries without losing the
        # underlying signal (e.g. "is labkit systematically blocking more
        # than legacy at the edges?").
        def record_divergence(key, labkit_decision, legacy_decision)
          agreement = labkit_decision == legacy_decision ? :match : :diverge
          shadow_counter.increment(key: key, agreement: agreement, boundary: window_boundary?(key))
        end

        private

        # Rules are built per check rather than memoized. Resolving threshold
        # and interval through ApplicationRateLimiter.threshold/.interval on
        # every call lets application-setting changes and test stubs of the
        # public threshold(key)/interval(key) methods propagate to the labkit
        # path; a memoized Rule would freeze whichever value resolved on
        # first construction. The Redis round-trip in `check` dominates
        # construction cost, so the per-call allocation is not load-bearing.
        def build_rule(key, spec)
          ::Labkit::RateLimit::Rule.new(
            name: spec[:rule_name],
            characteristics: spec[:characteristics],
            limit: ::Gitlab::ApplicationRateLimiter.threshold(key),
            period: ::Gitlab::ApplicationRateLimiter.interval(key),
            action: spec[:action]
          )
        end

        def identifier_for(rule, scope)
          values = Array(scope).flatten.compact

          rule.characteristics.zip(values).each_with_object({}) do |(char, value), hash|
            hash[char] = serialize_value(value) unless value.nil?
          end
        end

        # Coerces a scope value into a Redis-key-safe form for the labkit
        # identifier hash. Expected inputs across cohort 1 and cohort 2
        # call sites are:
        #   - String          (sha hex, IP, search scope name, hashed token)
        #   - Symbol          (:global for instance-wide scopes, sym discriminators)
        #   - Integer         (rare; most callers wrap the int in an AR model)
        #   - AR model #id    (User, Project, Group, Namespace, Environment, ...)
        # Anything else falls through to to_s as defence-in-depth: the
        # rate-limit path should produce a stable key for any input rather
        # than raise. The fallback is unreachable given current callers.
        def serialize_value(obj)
          case obj
          when String, Symbol then obj.to_s
          when Integer        then obj
          else
            obj.respond_to?(:id) ? obj.id : obj.to_s
          end
        end

        def window_boundary?(key)
          interval_seconds = ::Gitlab::ApplicationRateLimiter.interval(key)
          _, elapsed = Time.now.to_i.divmod(interval_seconds)
          elapsed < BOUNDARY_NOISE_SECONDS || elapsed >= interval_seconds - BOUNDARY_NOISE_SECONDS
        end

        # Resolved on every call rather than memoized at module scope.
        # Gitlab::Metrics.counter is itself memoized by name via the
        # Prometheus registry, so the per-call lookup is cheap and avoids
        # caching test doubles across examples.
        def shadow_counter
          ::Gitlab::Metrics.counter(
            :gitlab_rate_limiter_labkit_shadow_total,
            'Per-key agreement count between the labkit and legacy rate-limit paths during shadow validation.',
            { key: nil, agreement: nil, boundary: nil }
          )
        end

        # Records a labkit-handled key being called with an explicit
        # threshold or interval override. The labkit path can't honour
        # overrides (the Rule's limit/period are config-driven), so the
        # call routes back to legacy. Tracking gives us a path-to-removal
        # signal: which keys still see overrides, and how often.
        def record_override(key, threshold_override, interval_override)
          override_kind =
            if !threshold_override.nil? && !interval_override.nil?
              :both
            elsif !threshold_override.nil?
              :threshold
            else
              :interval
            end

          override_counter.increment(key: key, override: override_kind)
        end

        def override_counter
          ::Gitlab::Metrics.counter(
            :gitlab_rate_limiter_labkit_override_total,
            'Times a labkit-handled key was called with an explicit threshold or interval override, ' \
              'bypassing the labkit path.',
            { key: nil, override: nil }
          )
        end
      end
    end
  end
end
