import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Step1 from '~/organizations/index/components/reconciliation/steps/step_1.vue';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';

describe('ReconciliationStep1', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(Step1, {
      propsData: {
        organizations: [],
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findTotalOrganizations = () => wrapper.findByTestId('total-organizations');

  it('renders BaseStep', () => {
    createComponent();

    expect(wrapper.findComponent(BaseStep).exists()).toBe(true);
  });

  it('renders placeholder text', () => {
    createComponent();

    expect(wrapper.text()).toContain('Step 1 placeholder');
  });

  it('renders total organizations count', () => {
    createComponent({
      props: { organizations: [{ id: '1' }, { id: '2' }] },
    });

    expect(findTotalOrganizations().text()).toBe('Total Organizations: 2');
  });

  it('renders zero when organizations is empty', () => {
    createComponent();

    expect(findTotalOrganizations().text()).toBe('Total Organizations: 0');
  });
});
