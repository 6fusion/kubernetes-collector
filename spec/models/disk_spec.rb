RSpec.describe Disk do
  
  describe 'fields' do
    it { is_expected.to have_fields(:remote_id, :name, :storage_bytes) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:storage_bytes) }
    it { is_expected.to validate_numericality_of(:storage_bytes).greater_than_or_equal_to(0) }
  end

  describe 'associations matchers' do
    it { is_expected.to have_many :disk_samples }
    it { is_expected.to belong_to :machine }
  end
end