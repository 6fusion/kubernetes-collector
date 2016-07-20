RSpec.describe HostNic do
  describe 'fields' do
    it { is_expected.to have_fields(:name, :network_name, :speed_bits_per_second) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations matchers' do
    it { is_expected.to belong_to :host }
  end
end
