require "rails_helper"

describe Claim, type: :model, vcr: true do

  subject { FactoryGirl.create(:claim) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:work_id) }
  it { is_expected.to validate_presence_of(:service_id) }
end
