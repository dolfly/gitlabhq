import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import EditUserList from './components/edit_user_list.vue';
import createStore from './store/edit';

Vue.use(Vuex);

export const initEditUserList = () => {
  const el = document.getElementById('js-edit-user-list');

  if (!el) {
    return null;
  }

  const { userListsDocsPath } = el.dataset;

  return new Vue({
    el,
    name: 'FeatureFlagsEditUserListRoot',
    store: createStore(el.dataset),
    provide: { userListsDocsPath },
    render(h) {
      return h(EditUserList, {});
    },
  });
};
