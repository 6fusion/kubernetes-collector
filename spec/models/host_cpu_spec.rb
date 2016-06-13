RSpec.describe HostCpu do
  describe 'fields' do
    it { is_expected.to have_fields(:cores, :speed_hz) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:cores) }
    it { is_expected.to validate_presence_of(:speed_hz) }
    it { is_expected.to validate_numericality_of(:cores).greater_than_or_equal_to(1) }
    it { is_expected.to validate_numericality_of(:speed_hz).greater_than_or_equal_to(1) }
  end

  describe 'associations matchers' do
    it { is_expected.to belong_to :host }
  end
end
