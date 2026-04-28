import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlSprintf } from '@gitlab/ui';
import organizationsForReconciliationResponse from 'test_fixtures/graphql/organizations/organizations_for_reconciliation.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import ReconciliationModal from '~/organizations/index/components/reconciliation/modal.vue';
import organizationsForReconciliationQuery from '~/organizations/index/graphql/queries/organizations_for_reconciliation.query.graphql';
import Step1 from '~/organizations/index/components/reconciliation/steps/step_1.vue';
import Step2 from '~/organizations/index/components/reconciliation/steps/step_2.vue';
import Step3 from '~/organizations/index/components/reconciliation/steps/step_3.vue';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('OrganizationReconciliationModal', () => {
  let wrapper;
  let mockApollo;

  const successHandler = jest.fn().mockResolvedValue(organizationsForReconciliationResponse);

  const createComponent = ({ props = {}, handler = successHandler } = {}) => {
    mockApollo = createMockApollo([[organizationsForReconciliationQuery, handler]]);

    wrapper = shallowMount(ReconciliationModal, {
      apolloProvider: mockApollo,
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findStep1 = () => wrapper.findComponent(Step1);
  const findStep2 = () => wrapper.findComponent(Step2);
  const findStep3 = () => wrapper.findComponent(Step3);

  it('renders GlModal', () => {
    createComponent();

    expect(findModal().exists()).toBe(true);
  });

  it('passes visible prop to GlModal', () => {
    createComponent({ props: { visible: true } });

    expect(findModal().props('visible')).toBe(true);
  });

  it('defaults visible prop to false', () => {
    createComponent();

    expect(findModal().props('visible')).toBe(false);
  });

  it('emits change event when modal visibility changes', async () => {
    createComponent();

    await findModal().vm.$emit('change', true);

    expect(wrapper.emitted('change')).toEqual([[true]]);
  });

  describe('GraphQL query', () => {
    describe('when modal not visible', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not fetch organizations', () => {
        expect(successHandler).not.toHaveBeenCalled();
      });

      it('passes empty array when organizations have not loaded', () => {
        expect(findStep1().props('organizations')).toEqual([]);
      });
    });

    describe('when modal is visible', () => {
      beforeEach(async () => {
        createComponent({ props: { visible: true } });

        await waitForPromises();
      });

      it('fetches organizations', () => {
        expect(successHandler).toHaveBeenCalled();
      });

      it('passes organizations to step component', () => {
        expect(findStep1().props('organizations')).toEqual(
          organizationsForReconciliationResponse.data.organizations.nodes,
        );
      });
    });

    describe('when query fails', () => {
      const error = new Error();

      beforeEach(async () => {
        createComponent({
          props: { visible: true },
          handler: jest.fn().mockRejectedValue(error),
        });

        await waitForPromises();
      });

      it('calls createAlert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred fetching organizations. Please try again.',
          error,
          captureError: true,
        });
      });
    });
  });

  describe('step components', () => {
    describe('step 1', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders step 1 component', () => {
        expect(findStep1().exists()).toBe(true);
      });

      it('displays step progress text', () => {
        expect(findModal().text()).toContain('Step 1 / 3');
      });

      it('next event advances to step 2', async () => {
        findStep1().vm.$emit('next');
        await nextTick();

        expect(findStep2().exists()).toBe(true);
      });

      it('prev event closes modal', async () => {
        findStep1().vm.$emit('prev');
        await nextTick();

        expect(wrapper.emitted('change')).toEqual([[false]]);
      });
    });

    describe('step 2', () => {
      beforeEach(async () => {
        createComponent();

        findStep1().vm.$emit('next');
        await nextTick();
      });

      it('renders step 2 component', () => {
        expect(findStep2().exists()).toBe(true);
      });

      it('displays step progress text', () => {
        expect(findModal().text()).toContain('Step 2 / 3');
      });

      it('next event advances to step 3', async () => {
        findStep2().vm.$emit('next');
        await nextTick();

        expect(wrapper.findComponent(Step3).exists()).toBe(true);
      });

      it('prev event returns to step 1', async () => {
        findStep2().vm.$emit('prev');
        await nextTick();

        expect(wrapper.findComponent(Step1).exists()).toBe(true);
      });
    });

    describe('step 3', () => {
      beforeEach(async () => {
        createComponent();

        findStep1().vm.$emit('next');
        await nextTick();

        findStep2().vm.$emit('next');
        await nextTick();
      });

      it('renders step 3 component', () => {
        expect(findStep3().exists()).toBe(true);
      });

      it('displays step progress text', () => {
        expect(findModal().text()).toContain('Step 3 / 3');
      });

      it('next event does nothing and stays on step 3', async () => {
        findStep3().vm.$emit('next');
        await nextTick();

        expect(wrapper.findComponent(Step3).exists()).toBe(true);
      });

      it('prev event returns to step 2', async () => {
        findStep3().vm.$emit('prev');
        await nextTick();

        expect(wrapper.findComponent(Step2).exists()).toBe(true);
      });
    });
  });
});
