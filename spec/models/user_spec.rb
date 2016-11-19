require "rails_helper"
require "cancan/matchers"

describe User, type: :model, vcr: true do
  subject { FactoryGirl.create(:user, github: "mfenner") }

  it { is_expected.to validate_uniqueness_of(:uid) }
  it { is_expected.to validate_presence_of(:provider) }
  it { is_expected.to have_many(:claims) }

  describe "claims from ORCID" do
    subject { FactoryGirl.create(:valid_user) }

    it 'get data' do
      result = subject.get_data
      expect(result.length).to eq(26)
      work = result.first
      path = work.fetch('work-summary', [{}]).first.fetch("source", {}).fetch('source-client-id', {}).fetch('path', nil)
      expect(path).to eq(ENV['ORCID_CLIENT_ID'])
    end

    it 'parse data' do
      result = subject.get_data

      result = subject.parse_data(result)
      expect(result.length).to eq(26)
      expect(result.first).to eq("10.5167/UZH-19531")
    end
  end
end
