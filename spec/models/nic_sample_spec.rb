RSpec.describe NicSample do
  
  describe 'fields' do
    it { is_expected.to have_fields(:reading_at, :transmit_kilobits, :receive_kilobits) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:reading_at) }
    it { is_expected.to validate_presence_of(:transmit_kilobits) }
    it { is_expected.to validate_presence_of(:receive_kilobits) }
    it { is_expected.to validate_numericality_of(:transmit_kilobits).greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:receive_kilobits).greater_than_or_equal_to(0) }
  end

  describe 'associations matchers' do
    it { is_expected.to belong_to :nic }
  end
end