RSpec.describe DiskSample do
  describe 'fields' do
    it { is_expected.to have_fields(:reading_at, :usage_bytes, :read_kilobytes, :write_kilobytes) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:reading_at) }
    it { is_expected.to validate_presence_of(:usage_bytes) }
    it { is_expected.to validate_presence_of(:read_kilobytes) }
    it { is_expected.to validate_presence_of(:write_kilobytes) }
    it { is_expected.to validate_numericality_of(:usage_bytes).greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:read_kilobytes).greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:write_kilobytes).greater_than_or_equal_to(0) }
  end

  describe 'associations matchers' do
    it { is_expected.to belong_to :disk }
  end
end
