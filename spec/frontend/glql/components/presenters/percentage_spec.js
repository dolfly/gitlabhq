import { shallowMount } from '@vue/test-utils';
import PercentagePresenter from '~/glql/components/presenters/percentage.vue';

describe('PercentagePresenter', () => {
  let wrapper;

  const createComponent = (data) => {
    wrapper = shallowMount(PercentagePresenter, {
      propsData: { data },
    });
  };

  it('formats decimal as percentage', () => {
    createComponent(0.425);
    expect(wrapper.text()).toBe('42.5%');
  });

  it('handles zero correctly', () => {
    createComponent(0);
    expect(wrapper.text()).toBe('0%');
  });

  it('handles one correctly', () => {
    createComponent(1);
    expect(wrapper.text()).toBe('100%');
  });

  it('formats small percentages correctly', () => {
    createComponent(0.001);
    expect(wrapper.text()).toBe('0.1%');
  });

  it('formats high percentages correctly', () => {
    createComponent(0.9875);
    expect(wrapper.text()).toBe('98.8%');
  });
});
