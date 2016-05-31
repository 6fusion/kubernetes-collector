RSpec.describe Host do
  
  describe 'fields' do
    it { is_expected.to have_fields(:ip_address, :memory_bytes) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:ip_address) }
    it { is_expected.to validate_presence_of(:memory_bytes) }
    it { is_expected.to validate_numericality_of(:memory_bytes).greater_than_or_equal_to(0) }
  end

  describe 'associations matchers' do
    it { is_expected.to have_many :host_cpus }
    it { is_expected.to have_many :host_nics }
    it { is_expected.to have_many :host_disks }
    it { is_expected.to belong_to :infrastructure }
  end
end