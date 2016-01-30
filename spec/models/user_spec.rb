require "rails_helper"
require "cancan/matchers"

describe User, type: :model, vcr: true do

  subject { FactoryGirl.create(:user) }

  it { is_expected.to validate_uniqueness_of(:uid) }
  it { is_expected.to validate_presence_of(:provider) }
end
