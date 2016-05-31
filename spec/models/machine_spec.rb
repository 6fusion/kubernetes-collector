RSpec.describe Machine do
  
  describe 'fields' do
    it { is_expected.to have_fields(:remote_id, :name, :virtual_name, :cpu_count, :cpu_speed_hz, :memory_bytes, :tags, :status) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:virtual_name) }
    it { is_expected.to validate_presence_of(:cpu_count) }
    it { is_expected.to validate_presence_of(:cpu_speed_hz) }
    it { is_expected.to validate_presence_of(:memory_bytes) }
    it { is_expected.to validate_presence_of(:tags) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_numericality_of(:cpu_count).greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:cpu_speed_hz).greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:memory_bytes).greater_than_or_equal_to(0) }
  end

  describe 'associations matchers' do
    it { is_expected.to have_many :disks }
    it { is_expected.to have_many :nics }
    it { is_expected.to have_many :machine_samples }
    it { is_expected.to belong_to :pod }
  end
end