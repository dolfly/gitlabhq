<script>
import { GlAvatar, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { escape } from 'lodash';
import { getAdaptiveStatusColor } from '~/lib/utils/color_utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { REFERENCE_TYPES } from '~/content_editor/constants/reference_types';

export default {
  components: {
    GlAvatar,
    GlLoadingIcon,
    GlIcon,
  },

  directives: {
    SafeHtml,
  },

  props: {
    editor: {
      type: Object,
      required: true,
    },

    char: {
      type: String,
      required: true,
    },

    nodeType: {
      type: String,
      required: true,
    },

    nodeProps: {
      type: Object,
      required: true,
    },

    items: {
      type: Array,
      required: true,
    },

    command: {
      type: Function,
      required: true,
    },

    loading: {
      type: Boolean,
      required: false,
      default: false,
    },

    query: {
      type: String,
      required: false,
      default: '',
    },
  },

  data() {
    return {
      selectedIndex: -1,
    };
  },

  computed: {
    isReference() {
      return this.nodeType.startsWith('reference');
    },

    isCommand() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.COMMAND;
    },

    isUser() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.USER;
    },

    isIssue() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.ISSUE;
    },

    isIssueAlternative() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.ISSUE_ALTERNATIVE;
    },

    isWorkItem() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.WORK_ITEM;
    },

    isLabel() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.LABEL;
    },

    isEpic() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.EPIC;
    },

    isSnippet() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.SNIPPET;
    },

    isVulnerability() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.VULNERABILITY;
    },

    isIteration() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.ITERATION;
    },

    isStatus() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.STATUS;
    },

    isMergeRequest() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.MERGE_REQUEST;
    },

    isMilestone() {
      return this.isReference && this.nodeProps.referenceType === REFERENCE_TYPES.MILESTONE;
    },

    isWiki() {
      return this.nodeProps.referenceType === REFERENCE_TYPES.WIKI;
    },

    isEmoji() {
      return this.nodeType === REFERENCE_TYPES.EMOJI;
    },

    shouldSelectFirstItem() {
      return this.items.length && this.query;
    },
  },

  watch: {
    items() {
      this.selectedIndex = this.shouldSelectFirstItem ? 0 : -1;
    },
    async selectedIndex(val) {
      // wait for the DOM to update before scrolling
      await this.$nextTick();
      this.scrollIntoView();

      // a11y: set aria-activedescendant to the tiptap editor
      const activeDescendantId = val >= 0 ? `suggestion-option-${val}` : '';
      this.editor.view.dom.setAttribute('aria-activedescendant', activeDescendantId);
    },
  },

  mounted() {
    if (this.shouldSelectFirstItem) {
      this.selectedIndex = 0;
    }
  },

  methods: {
    getAdaptiveStatusColor,

    getText(item) {
      if (this.isEmoji) return item.emoji.e;

      switch (this.isReference && this.nodeProps.referenceType) {
        case REFERENCE_TYPES.USER:
          return `${this.char}${item.username}`;
        case REFERENCE_TYPES.ISSUE:
        case REFERENCE_TYPES.MERGE_REQUEST:
          return item.reference || `${this.char}${item.iid}`;
        case REFERENCE_TYPES.ISSUE_ALTERNATIVE:
        case REFERENCE_TYPES.WORK_ITEM:
          return item.reference || `#${item.iid}`;
        case REFERENCE_TYPES.SNIPPET:
          return `${this.char}${item.id}`;
        case REFERENCE_TYPES.MILESTONE:
          return `${this.char}${item.title}`;
        case REFERENCE_TYPES.LABEL:
          return item.title;
        case REFERENCE_TYPES.COMMAND:
          return `${this.char}${item.name}`;
        case REFERENCE_TYPES.EPIC:
          return item.reference;
        case REFERENCE_TYPES.VULNERABILITY:
          return `[vulnerability:${item.id}]`;
        case REFERENCE_TYPES.WIKI:
        case REFERENCE_TYPES.ITERATION:
          return item.title;
        case REFERENCE_TYPES.STATUS:
          return `${this.char}${item.name}${this.char}`;
        default:
          return '';
      }
    },

    getProps(item) {
      const props = {};

      if (this.isEmoji) {
        Object.assign(props, {
          name: item.emoji.name,
          unicodeVersion: item.emoji.u,
          title: item.emoji.d,
          moji: item.emoji.e,
        });
      }

      if (this.isLabel || this.isMilestone) {
        Object.assign(props, {
          originalText: `${this.char}${
            /\W/.test(item.title) ? JSON.stringify(item.title) : item.title
          }`,
        });
      }

      if (this.isLabel) {
        Object.assign(props, {
          text: item.title,
          color: item.color,
        });
      }

      if (this.isWiki) {
        Object.assign(props, {
          text: item.title,
          href: item.path,
          isGollumLink: true,
          isWikiPage: true,
          canonicalSrc: item.slug,
        });
      }

      if (this.isIteration) {
        Object.assign(props, {
          originalText: item.reference,
        });
      }

      if (this.isStatus) {
        Object.assign(props, {
          originalText: `${this.char}${item.name}${this.char}`,
        });
      }

      Object.assign(props, this.nodeProps);

      return props;
    },

    // eslint-disable-next-line vue/no-unused-properties -- onKeyDown() is part of the component's public API.
    onKeyDown({ event }) {
      if (!this.items.length) return false;

      if (event.key === 'ArrowUp') {
        this.upHandler();
        return true;
      }

      if (event.key === 'ArrowDown') {
        this.downHandler();
        return true;
      }

      if (event.key === 'Enter' || event.key === 'Tab') {
        this.enterHandler();
        return true;
      }

      return false;
    },

    upHandler() {
      this.selectedIndex = (this.selectedIndex + this.items.length - 1) % this.items.length;
    },

    downHandler() {
      this.selectedIndex = (this.selectedIndex + 1) % this.items.length;
    },

    enterHandler() {
      this.selectItem(this.selectedIndex);
    },

    scrollIntoView() {
      this.$refs.dropdownItems?.[this.selectedIndex]?.scrollIntoView({ block: 'nearest' });
    },

    selectItem(index) {
      const item = this.items[index];

      if (item) {
        this.command({
          text: this.getText(item),
          ...this.getProps(item),
        });
      }
    },

    avatarSubLabel(item) {
      return item.count ? `${item.name} (${item.count})` : item.name;
    },

    highlight(text) {
      return this.query
        ? String(escape(text)).replace(
            new RegExp(this.query, 'i'),
            (match) => `<strong class="!gl-text-default">${match}</strong>`,
          )
        : escape(text);
    },
  },
  safeHtmlConfig: { ALLOWED_TAGS: ['strong'], ALLOW_DATA_ATTR: false },
};
</script>

<template>
  <div class="gl-new-dropdown content-editor-suggestions-dropdown">
    <div v-if="!loading && items.length > 0" class="gl-new-dropdown-panel gl-absolute !gl-block">
      <div class="gl-new-dropdown-inner">
        <ul
          id="content-editor-suggestions"
          class="gl-new-dropdown-contents"
          data-testid="content-editor-suggestions-dropdown"
          role="listbox"
          :aria-label="__(`Suggestions`)"
        >
          <li
            v-for="(item, index) in items"
            :id="`suggestion-option-${index}`"
            :key="index"
            role="option"
            class="gl-new-dropdown-item"
            :class="{ focused: index === selectedIndex }"
          >
            <div
              :id="`suggestion-option-${index}`"
              ref="dropdownItems"
              type="button"
              role="option"
              :aria-selected="index === selectedIndex ? 'true' : 'false'"
              class="gl-new-dropdown-item-content"
              @click="selectItem(index)"
            >
              <div class="gl-new-dropdown-item-text-wrapper">
                <span v-if="isUser" class="gl-flex gl-items-center gl-gap-3">
                  <gl-avatar
                    :src="item.avatar_url"
                    :entity-name="item.username"
                    :size="24"
                    :shape="item.type === 'Group' ? 'rect' : 'circle'"
                  />
                  <span>
                    <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.username)"></span>
                    <small
                      v-safe-html:[$options.safeHtmlConfig]="highlight(avatarSubLabel(item))"
                      class="gl-text-subtle"
                    ></small>
                  </span>
                </span>
                <span v-if="isIssue || isIssueAlternative || isWorkItem || isMergeRequest">
                  <gl-icon
                    v-if="item.icon_name"
                    class="gl-mr-2"
                    variant="subtle"
                    :name="item.icon_name"
                  />
                  <small
                    v-safe-html:[$options.safeHtmlConfig]="highlight(item.reference || item.iid)"
                    class="gl-text-subtle"
                  ></small>
                  <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.title)"></span>
                </span>
                <span v-if="isVulnerability || isSnippet">
                  <small
                    v-safe-html:[$options.safeHtmlConfig]="highlight(item.id)"
                    class="gl-text-subtle"
                  ></small>
                  <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.title)"></span>
                </span>
                <span v-if="isEpic || isIteration">
                  <small
                    v-safe-html:[$options.safeHtmlConfig]="highlight(item.reference)"
                    class="gl-text-subtle"
                  ></small>
                  <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.title)"></span>
                </span>
                <span v-if="isStatus">
                  <gl-icon
                    class="gl-mr-2"
                    :name="item.iconName"
                    :size="12"
                    :style="`color: ${getAdaptiveStatusColor(item.color)}`"
                  />
                  <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.name)"></span>
                </span>
                <span v-if="isMilestone">
                  <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.title)"></span>
                  <span v-if="item.expired">{{ __('(expired)') }}</span>
                </span>
                <span v-if="isWiki">
                  <gl-icon class="gl-mr-2" name="document" />
                  <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.title)"></span>
                  <small
                    v-if="item.title.toLowerCase() !== item.slug.toLowerCase()"
                    v-safe-html:[$options.safeHtmlConfig]="highlight(`(${item.slug})`)"
                    class="gl-text-subtle"
                  ></small>
                </span>
                <span v-if="isLabel" class="gl-flex">
                  <span
                    data-testid="label-color-box"
                    class="dropdown-label-box gl-top-0 gl-mr-3 gl-shrink-0"
                    :style="{ backgroundColor: item.color }"
                  ></span>
                  <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.title)"></span>
                </span>
                <div v-if="isCommand">
                  <div class="gl-mb-1">
                    /<span v-safe-html:[$options.safeHtmlConfig]="highlight(item.name)"></span>
                    <span class="gl-text-sm gl-text-subtle">{{ item.params[0] }}</span>
                  </div>
                  <em
                    v-safe-html:[$options.safeHtmlConfig]="highlight(item.description)"
                    class="gl-text-sm gl-text-subtle"
                  ></em>
                </div>
                <div v-if="isEmoji" class="gl-flex gl-items-center">
                  <div class="gl-pr-4 gl-text-lg">
                    <gl-emoji
                      :key="item.emoji.name"
                      :data-name="item.emoji.name"
                      :title="item.emoji.d"
                      :data-unicode-version="item.emoji.u"
                      :data-fallback-src="item.emoji.src"
                      >{{ item.emoji.e }}</gl-emoji
                    >
                  </div>
                  <div class="gl-grow">
                    <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.fieldValue)"></span>
                  </div>
                </div>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>
    <div v-if="loading" class="gl-new-dropdown-panel gl-absolute !gl-block">
      <div class="gl-new-dropdown-inner">
        <div class="gl-px-4 gl-py-3">
          <gl-loading-icon size="sm" class="gl-inline-block" /> {{ __('Loading…') }}
        </div>
      </div>
    </div>
  </div>
</template>
