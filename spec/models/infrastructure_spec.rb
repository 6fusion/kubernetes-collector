RSpec.describe Infrastructure do
  
  describe 'fields' do
    it { is_expected.to have_fields(:remote_id, :organization_id, :name, :tags) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:organization_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:tags) }
  end

  describe 'associations matchers' do
    it { is_expected.to have_many :hosts }
    it { is_expected.to have_many :pods }
  end
end