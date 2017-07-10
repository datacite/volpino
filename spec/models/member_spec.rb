require "rails_helper"

describe Member, type: :model, vcr: true do

  subject { FactoryGirl.create(:member) }

  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_presence_of(:country_code) }
  it { is_expected.to validate_presence_of(:year) }
end
