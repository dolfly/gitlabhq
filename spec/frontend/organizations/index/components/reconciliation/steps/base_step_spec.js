import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';

describe('ReconciliationBaseStep', () => {
  let wrapper;

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMount(BaseStep, {
      propsData: {
        ...props,
      },
      slots: {
        default: '<p>Slot content</p>',
        ...slots,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);

  it('renders default slot content', () => {
    createComponent();

    expect(wrapper.text()).toContain('Slot content');
  });

  it('renders icon when provided', () => {
    createComponent({ props: { icon: 'search' } });

    expect(findIcon().props('name')).toBe('search');
  });

  it('does not render icon when not provided', () => {
    createComponent();

    expect(findIcon().exists()).toBe(false);
  });

  it('renders title when provided', () => {
    createComponent({ props: { title: 'Step title' } });

    expect(wrapper.find('h4').text()).toBe('Step title');
  });

  it('does not render title when not provided', () => {
    createComponent();

    expect(wrapper.find('h4').exists()).toBe(false);
  });
});
