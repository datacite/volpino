require "rails_helper"

describe Tag, type: :model do
  subject { FactoryGirl.create(:tag) }

  it { is_expected.to have_and_belong_to_many(:services) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_uniqueness_of(:title) }
end
