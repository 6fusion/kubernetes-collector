RSpec.describe Pod do
  describe 'fields' do
    it { is_expected.to have_fields(:name) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations matchers' do
    it { is_expected.to have_many :machines }
    it { is_expected.to belong_to :infrastructure }
  end
end
