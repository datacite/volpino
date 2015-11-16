require "rails_helper"

describe Service, type: :model, vcr: true do

  subject { FactoryGirl.create(:service) }

  it { is_expected.to have_many(:claims) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_uniqueness_of(:title) }
  it { is_expected.to validate_uniqueness_of(:redirect_uri) }
end
