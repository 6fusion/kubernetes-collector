RSpec.describe Nic do
  
  describe 'fields' do
    it { is_expected.to have_fields(:remote_id, :name, :kind) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:kind) }
  end

  describe 'associations matchers' do
    it { is_expected.to have_many :nic_samples }
    it { is_expected.to belong_to :machine }
  end
end