import { mount } from '@vue/test-utils';
import PanelActions from '~/vue_shared/components/panel_actions.vue';

describe('PanelActions', () => {
  let wrapper;

  const findCloseButton = () => wrapper.find('button');

  const createComponent = (options = {}) => {
    wrapper = mount(PanelActions, options);
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the close button', () => {
    expect(findCloseButton().exists()).toBe(true);
  });

  it('close button has the correct aria-label', () => {
    expect(findCloseButton().attributes('aria-label')).toBe('Close panel');
  });

  it('emits close when the close button is clicked', async () => {
    await findCloseButton().trigger('click');
    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('renders default slot content', () => {
    const CustomAction = { template: '<button>Custom action</button>' };
    createComponent({ slots: { default: CustomAction } });
    expect(wrapper.findComponent(CustomAction).exists()).toBe(true);
  });
});
