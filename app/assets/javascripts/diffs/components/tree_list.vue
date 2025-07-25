<script>
import {
  GlTooltipDirective,
  GlBadge,
  GlButtonGroup,
  GlButton,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import micromatch from 'micromatch';
import { getModifierKey } from '~/constants';
import { s__, sprintf } from '~/locale';
import { RecycleScroller } from 'vendor/vue-virtual-scroller';
import { isElementClipped } from '~/lib/utils/common_utils';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import DiffFileRow from './diff_file_row.vue';

const MODIFIER_KEY = getModifierKey();

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlBadge,
    GlButtonGroup,
    GlButton,
    DiffFileRow,
    RecycleScroller,
    GlSearchBoxByType,
  },
  props: {
    hideFileStats: {
      type: Boolean,
      required: true,
    },
    loadedFiles: {
      type: Object,
      required: false,
      default: null,
    },
    totalFilesCount: {
      type: [Number, String],
      default: undefined,
      required: false,
    },
    rowHeight: {
      type: Number,
      required: true,
    },
    groupBlobsListItems: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      search: '',
    };
  },
  computed: {
    ...mapState(useLegacyDiffs, [
      'renderTreeList',
      'currentDiffFileId',
      'viewedDiffFileIds',
      'fileTree',
      'allBlobs',
      'linkedFile',
      'flatBlobsList',
    ]),
    flatUngroupedList() {
      return this.flatBlobsList.reduce((acc, blob, index) => {
        const loading = this.isLoading(blob.fileHash);
        const lastIndex = acc.length;
        const previous = acc[lastIndex - 1];
        const adjacentNonHeader = previous?.isHeader ? acc[lastIndex - 2] : previous;
        const isSibling = adjacentNonHeader?.parentPath === blob.parentPath;
        if (isSibling) return [...acc, { ...blob, loading, level: 1 }];
        const header = {
          key: `header-${index}`,
          path: blob.parentPath,
          isHeader: true,
          tree: [],
          level: 0,
        };
        return [...acc, header, { ...blob, loading, level: 1 }];
      }, []);
    },
    filteredTreeList() {
      let search = this.search.toLowerCase().trim();

      if (search === '') {
        return this.renderTreeList ? this.fileTree : this.allBlobs;
      }

      const searchSplit = search.split(',').filter((t) => t);

      if (searchSplit.length > 1) {
        search = `(${searchSplit.map((s) => s.replace(/(^ +| +$)/g, '')).join('|')})`;
      } else {
        [search] = searchSplit;
      }

      return this.allBlobs.reduce((acc, folder) => {
        const tree = folder.tree.filter((f) =>
          micromatch.contains(f.path, search, { nocase: true }),
        );

        if (tree.length) {
          return acc.concat({
            ...folder,
            tree,
          });
        }

        return acc;
      }, []);
    },
    // Flatten the treeList so there's no nested trees
    // This gives us fixed row height for virtual scrolling
    // in:  [{ path: 'a', tree: [{ path: 'b' }] }, { path: 'c' }]
    // out: [{ path: 'a', tree: [{ path: 'b' }] }, { path: 'b' }, { path: 'c' }]
    flatFilteredTreeList() {
      const result = [];
      const createFlatten = (level, hidden) => (item) => {
        const isTree = item.type === 'tree';
        const loading = !isTree && !item.isHeader && this.isLoading(item.fileHash);
        result.push({
          ...item,
          hidden,
          level: item.isHeader ? 0 : level,
          key: item.key || item.path,
          loading,
        });
        const isHidden = hidden || (isTree && !item.opened);
        item.tree.forEach(createFlatten(level + 1, isHidden));
      };

      this.filteredTreeList.forEach(createFlatten(0));

      return result;
    },
    flatListWithLinkedFile() {
      const result = [...this.flatFilteredTreeList];
      const linkedFileIndex = result.findIndex((item) => item.path === this.linkedFile.file_path);
      const [linkedFileItem] = result.splice(linkedFileIndex, 1);

      if (linkedFileItem.parentPath === '/')
        return [{ ...linkedFileItem, level: 0, linked: true, hidden: false }, ...result];

      // remove detached folder from the tree
      const next = result[linkedFileIndex];
      const prev = result[linkedFileIndex - 1];
      const hasContainingFolder =
        prev && prev.type === 'tree' && prev.level === linkedFileItem.level - 1;
      const hasSibling = next && next.type !== 'tree' && next.level === linkedFileItem.level;
      if (hasContainingFolder && !hasSibling) {
        // folder tree is always condensed so we only need to remove the parent folder
        result.splice(linkedFileIndex - 1, 1);
      }

      return [
        {
          level: 0,
          key: 'linked-path',
          isHeader: true,
          opened: true,
          path: linkedFileItem.parentPath,
          type: 'tree',
          hidden: false,
        },
        { ...linkedFileItem, level: 1, linked: true, hidden: false },
        ...result,
      ];
    },
    treeList() {
      if (!this.renderTreeList && !this.groupBlobsListItems && !this.search)
        return this.flatUngroupedList;
      const list = this.linkedFile ? this.flatListWithLinkedFile : this.flatFilteredTreeList;
      if (this.search) return list;
      return list.filter((item) => !item.hidden);
    },
  },
  watch: {
    currentDiffFileId(hash) {
      if (hash) {
        this.openFileTree(hash);
        this.preventClippingSelectedFile(hash);
      }
    },
  },
  methods: {
    ...mapActions(useLegacyDiffs, ['setRenderTreeList', 'setTreeOpen']),
    preventClippingSelectedFile(hash) {
      // let the layout stabilize, we need to wait for:
      // scroll to file, sticky elements update, file browser height update
      // file browser height might be shrunk, so we need to scroll to the selected file
      setTimeout(() => {
        this.scrollVirtualScrollerToFileHash(hash);
      }, 20);
    },
    scrollVirtualScrollerToFileHash(hash) {
      const item = document.querySelector(`[data-file-row="${hash}"]`);
      if (item && !isElementClipped(item, this.$refs.scroller.$el)) return;
      const index = this.treeList.findIndex((f) => f.fileHash === hash);
      if (index !== -1) {
        this.$refs.scroller?.scrollToItem?.(index);
      }
    },
    openFileTree(hash) {
      const file = this.flatFilteredTreeList.find((f) => f.fileHash === hash);

      if (file) {
        file.path
          .split('/')
          .slice(0, -1)
          .reduce((acc, part) => [...acc, acc.length ? `${acc.at(-1)}/${part}` : part], [])
          .forEach((path) => this.setTreeOpen({ path, opened: true }));
      }
    },
    isLoading(fileHash) {
      return this.loadedFiles && !this.loadedFiles[fileHash];
    },
  },
  searchPlaceholder: sprintf(s__('MergeRequest|Search (e.g. *.vue) (%{MODIFIER_KEY}P)'), {
    MODIFIER_KEY,
  }),
};
</script>

<template>
  <section
    class="tree-list-holder gl-flex gl-flex-col"
    data-testid="file-tree-container"
    aria-labelledby="tree-list-title"
  >
    <div class="gl-mb-3 gl-flex gl-items-center">
      <h2
        id="tree-list-title"
        class="gl-my-0 gl-inline-block gl-text-base"
        :aria-label="__('File browser')"
      >
        {{ __('Files') }}
      </h2>
      <gl-badge
        v-if="totalFilesCount != null"
        class="gl-ml-2"
        data-testid="file-count"
        aria-hidden="true"
        >{{ totalFilesCount }}</gl-badge
      >
      <gl-button-group class="gl-ml-auto">
        <gl-button
          v-gl-tooltip.hover
          icon="list-bulleted"
          :selected="!renderTreeList"
          :title="__('List view')"
          :aria-label="__('List view')"
          data-testid="list-view-toggle"
          @click="setRenderTreeList({ renderTreeList: false })"
        />
        <gl-button
          v-gl-tooltip.hover
          icon="file-tree"
          :selected="renderTreeList"
          :title="__('Tree view')"
          :aria-label="__('Tree view')"
          data-testid="tree-view-toggle"
          @click="setRenderTreeList({ renderTreeList: true })"
        />
      </gl-button-group>
    </div>
    <gl-search-box-by-type
      id="diff-tree-search"
      v-model="search"
      :placeholder="$options.searchPlaceholder"
      name="diff-tree-search"
      data-testid="diff-tree-search"
      :clear-button-title="__('Clear search')"
      class="gl-mb-3"
    />
    <nav
      :class="{ 'tree-list-blobs': !renderTreeList || search }"
      class="mr-tree-list"
      :aria-label="__('File tree')"
    >
      <recycle-scroller
        v-if="treeList.length"
        ref="scroller"
        :items="treeList"
        :item-size="rowHeight"
        :buffer="100"
        key-field="key"
        data-testid="tree-list-scroll"
      >
        <template #default="{ item }">
          <diff-file-row
            :file="item"
            :level="item.level"
            :viewed-files="viewedDiffFileIds"
            :hide-file-stats="hideFileStats"
            :current-diff-file-id="currentDiffFileId"
            :style="{ '--level': item.level }"
            :class="{ 'tree-list-parent': item.level > 0 }"
            :tabindex="item.loading ? -1 : 0"
            class="gl-relative"
            :data-file-row="item.fileHash"
            @toggleTreeOpen="$emit('toggleFolder', $event)"
            @clickFile="!item.loading && $emit('clickFile', $event)"
          />
        </template>
        <template #after>
          <div class="tree-list-gutter"></div>
        </template>
      </recycle-scroller>
      <p v-else class="gl-my-3">
        {{ s__('MergeRequest|No files found') }}
      </p>
    </nav>
  </section>
</template>

<style>
.tree-list-blobs .file-row-name {
  margin-left: 12px;
}
</style>
