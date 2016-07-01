RSpec.describe MachineSample do
  describe 'fields' do
    it { is_expected.to have_fields(:reading_at, :cpu_usage_percent, :memory_bytes) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:reading_at) }
    it { is_expected.to validate_presence_of(:cpu_usage_percent) }
    it { is_expected.to validate_presence_of(:memory_bytes) }
    it { is_expected.to validate_numericality_of(:cpu_usage_percent).greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:memory_bytes).greater_than_or_equal_to(0) }
  end

  describe 'associations matchers' do
    it { is_expected.to belong_to :machine }
  end
end
